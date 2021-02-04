/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_measurement.h"

VALUE mMeasure;
VALUE cRpMeasurement;

prof_measurer_t* prof_measurer_allocations(bool track_allocations);
prof_measurer_t* prof_measurer_memory(bool track_allocations);
prof_measurer_t* prof_measurer_process_time(bool track_allocations);
prof_measurer_t* prof_measurer_wall_time(bool track_allocations);

void rp_init_measure_allocations(void);
void rp_init_measure_memory(void);
void rp_init_measure_process_time(void);
void rp_init_measure_wall_time(void);

prof_measurer_t* prof_get_measurer(prof_measure_mode_t measure, bool track_allocations)
{
    switch (measure)
    {
    case MEASURE_WALL_TIME:
        return prof_measurer_wall_time(track_allocations);
    case MEASURE_PROCESS_TIME:
        return prof_measurer_process_time(track_allocations);
    case MEASURE_ALLOCATIONS:
        return prof_measurer_allocations(track_allocations);
    case MEASURE_MEMORY:
        return prof_measurer_memory(track_allocations);
    default:
        rb_raise(rb_eArgError, "Unknown measure mode: %d", measure);
    }
};

double prof_measure(prof_measurer_t* measurer, rb_trace_arg_t* trace_arg)
{
    double measurement = measurer->measure(trace_arg);
    return measurement * measurer->multiplier;
}

/* =======  prof_measurement_t   ========*/
prof_measurement_t* prof_measurement_create(void)
{
    prof_measurement_t* result = ALLOC(prof_measurement_t);
    result->total_time = 0;
    result->self_time = 0;
    result->wait_time = 0;
    result->called = 0;
    result->object = Qnil;
    return result;
}

void prof_measurement_mark(void* data)
{
    if (!data) return;

    prof_measurement_t* measurement_data = (prof_measurement_t*)data;

    if (measurement_data->object != Qnil)
        rb_gc_mark(measurement_data->object);
}

static void prof_measurement_ruby_gc_free(void* data)
{
    if (data)
    {
        // Measurements are freed by their owning object (call info or method)
        prof_measurement_t* measurement = (prof_measurement_t*)data;
        measurement->object = Qnil;
    }
}

void prof_measurement_free(prof_measurement_t* measurement)
{
    /* Has this measurement object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (measurement->object != Qnil)
    {
        RTYPEDDATA(measurement->object)->data = NULL;
        measurement->object = Qnil;
    }

    xfree(measurement);
}

size_t prof_measurement_size(const void* data)
{
    return sizeof(prof_measurement_t);
}

static const rb_data_type_t measurement_type =
{
    .wrap_struct_name = "Measurement",
    .function =
    {
        .dmark = prof_measurement_mark,
        .dfree = prof_measurement_ruby_gc_free,
        .dsize = prof_measurement_size,
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE prof_measurement_wrap(prof_measurement_t* measurement)
{
    if (measurement->object == Qnil)
    {
        measurement->object = TypedData_Wrap_Struct(cRpMeasurement, &measurement_type, measurement);
    }
    return measurement->object;
}

static VALUE prof_measurement_allocate(VALUE klass)
{
    prof_measurement_t* measurement = prof_measurement_create();
    measurement->object = prof_measurement_wrap(measurement);
    return measurement->object;
}

prof_measurement_t* prof_get_measurement(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_measurement_t* result = RTYPEDDATA_DATA(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::Measurement instance has already been freed, likely because its profile has been freed.");

    return result;
}

/* call-seq:
   total_time -> float

Returns the total amount of time spent in this method and its children. */
static VALUE prof_measurement_total_time(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);
    return rb_float_new(result->total_time);
}

/* call-seq:
   self_time -> float

Returns the total amount of time spent in this method. */
static VALUE
prof_measurement_self_time(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);

    return rb_float_new(result->self_time);
}

/* call-seq:
   wait_time -> float

Returns the total amount of time this method waited for other threads. */
static VALUE prof_measurement_wait_time(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);

    return rb_float_new(result->wait_time);
}

/* call-seq:
   called -> int

Returns the total amount of times this method was called. */
static VALUE prof_measurement_called(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);
    return INT2NUM(result->called);
}

/* call-seq:
   called=n -> n

Sets the call count to n. */
static VALUE prof_measurement_set_called(VALUE self, VALUE called)
{
    prof_measurement_t* result = prof_get_measurement(self);
    result->called = NUM2INT(called);
    return called;
}

/* :nodoc: */
static VALUE
prof_measurement_dump(VALUE self)
{
    prof_measurement_t* measurement_data = prof_get_measurement(self);
    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("total_time")), rb_float_new(measurement_data->total_time));
    rb_hash_aset(result, ID2SYM(rb_intern("self_time")), rb_float_new(measurement_data->self_time));
    rb_hash_aset(result, ID2SYM(rb_intern("wait_time")), rb_float_new(measurement_data->wait_time));
    rb_hash_aset(result, ID2SYM(rb_intern("called")), INT2FIX(measurement_data->called));

    return result;
}

/* :nodoc: */
static VALUE
prof_measurement_load(VALUE self, VALUE data)
{
    prof_measurement_t* measurement = prof_get_measurement(self);
    measurement->object = self;

    measurement->total_time = rb_num2dbl(rb_hash_aref(data, ID2SYM(rb_intern("total_time"))));
    measurement->self_time = rb_num2dbl(rb_hash_aref(data, ID2SYM(rb_intern("self_time"))));
    measurement->wait_time = rb_num2dbl(rb_hash_aref(data, ID2SYM(rb_intern("wait_time"))));
    measurement->called = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("called"))));

    return data;
}

void rp_init_measure()
{
    mMeasure = rb_define_module_under(mProf, "Measure");
    rp_init_measure_wall_time();
    rp_init_measure_process_time();
    rp_init_measure_allocations();
    rp_init_measure_memory();

    cRpMeasurement = rb_define_class_under(mProf, "Measurement", rb_cObject);
    rb_undef_method(CLASS_OF(cRpMeasurement), "new");
    rb_define_alloc_func(cRpMeasurement, prof_measurement_allocate);

    rb_define_method(cRpMeasurement, "called", prof_measurement_called, 0);
    rb_define_method(cRpMeasurement, "called=", prof_measurement_set_called, 1);
    rb_define_method(cRpMeasurement, "total_time", prof_measurement_total_time, 0);
    rb_define_method(cRpMeasurement, "self_time", prof_measurement_self_time, 0);
    rb_define_method(cRpMeasurement, "wait_time", prof_measurement_wait_time, 0);

    rb_define_method(cRpMeasurement, "_dump_data", prof_measurement_dump, 0);
    rb_define_method(cRpMeasurement, "_load_data", prof_measurement_load, 1);
}
