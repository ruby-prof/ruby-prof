/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"

VALUE mMeasure;
VALUE cMeasurement;

prof_measurer_t* prof_measurer_allocations(void);
prof_measurer_t* prof_measurer_memory(void);
prof_measurer_t* prof_measurer_process_time(void);
prof_measurer_t* prof_measurer_wall_time(void);

void rp_init_measure_allocations(void);
void rp_init_measure_memory(void);
void rp_init_measure_process_time(void);
void rp_init_measure_wall_time(void);

prof_measurer_t* prof_get_measurer(prof_measure_mode_t measure)
{
    switch (measure) {
    case MEASURE_WALL_TIME:
        return prof_measurer_wall_time();
    case MEASURE_PROCESS_TIME:
        return prof_measurer_process_time();
    case MEASURE_ALLOCATIONS:
        return prof_measurer_allocations();
    case MEASURE_MEMORY:
        return prof_measurer_memory();
    default:
        rb_raise(rb_eArgError, "Unknown measure mode: %d", measure);
    }
};

double prof_measure(prof_measurer_t* measurer)
{
    double measurement = measurer->measure();
    return measurement * measurer->multiplier;
}

/* =======  prof_measurement_t   ========*/
prof_measurement_t *prof_measurement_create(void)
{
    prof_measurement_t* result = ALLOC(prof_measurement_t);
    result->total_time = 0;
    result->self_time = 0;
    result->wait_time = 0;
    result->called = 0;
    result->object = Qnil;
    return result;
}

static void
prof_measurement_ruby_gc_free(prof_measurement_t* measurement)
{
    /* Has this thread object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (measurement->object != Qnil)
    {
        RDATA(measurement->object)->data = NULL;
        RDATA(measurement->object)->dfree = NULL;
        RDATA(measurement->object)->dmark = NULL;
    }
    measurement->object = Qnil;
}

void
prof_measurement_mark(prof_measurement_t* measurement)
{
    if (measurement->object != Qnil)
        rb_gc_mark(measurement->object);
}

VALUE
prof_measurement_wrap(prof_measurement_t* measurement)
{
    if (measurement->object == Qnil)
    {
        measurement->object = Data_Wrap_Struct(cMeasurement, prof_measurement_mark, prof_measurement_ruby_gc_free, measurement);
    }
    return measurement->object;
}

static VALUE
prof_measurement_allocate(VALUE klass)
{
    prof_measurement_t *measurement = prof_measurement_create();
    measurement->object = prof_measurement_wrap(measurement);
    return measurement->object;
}

prof_measurement_t*
prof_get_measurement(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_measurement_t* result = DATA_PTR(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::Measurement instance has already been freed, likely because its profile has been freed.");

    return result;
}

/* call-seq:
   total_time -> float

Returns the total amount of time spent in this method and its children. */
static VALUE
prof_measurement_total_time(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);
    return rb_float_new(result->total_time);
}

/* call-seq:
   add_total_time(measurement) -> nil

adds total time time from measurement to self. */
static VALUE
prof_measurement_add_total_time(VALUE self, VALUE other)
{
    prof_measurement_t* result = prof_get_measurement(self);
    prof_measurement_t* other_info = prof_get_measurement(other);

    result->total_time += other_info->total_time;
    return Qnil;
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
   add_self_time(measurement) -> nil

adds self time from measurement to self. */
static VALUE
prof_measurement_add_self_time(VALUE self, VALUE other)
{
    prof_measurement_t* result = prof_get_measurement(self);
    prof_measurement_t* other_info = prof_get_measurement(other);

    result->self_time += other_info->self_time;
    return Qnil;
}

/* call-seq:
   wait_time -> float

Returns the total amount of time this method waited for other threads. */
static VALUE
prof_measurement_wait_time(VALUE self)
{
    prof_measurement_t* result = prof_get_measurement(self);

    return rb_float_new(result->wait_time);
}

/* call-seq:
   add_wait_time(measurement) -> nil

adds wait time from measurement to self. */

static VALUE
prof_measurement_add_wait_time(VALUE self, VALUE other)
{
    prof_measurement_t* result = prof_get_measurement(self);
    prof_measurement_t* other_info = prof_get_measurement(other);

    result->wait_time += other_info->wait_time;
    return Qnil;
}

/* call-seq:
   called -> int

Returns the total amount of times this method was called. */
static VALUE
prof_measurement_called(VALUE self)
{
    prof_measurement_t *result = prof_get_measurement(self);
    return INT2NUM(result->called);
}

/* call-seq:
   called=n -> n

Sets the call count to n. */
static VALUE
prof_measurement_set_called(VALUE self, VALUE called)
{
    prof_measurement_t *result = prof_get_measurement(self);
    result->called = NUM2INT(called);
    return called;
}

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

static VALUE
prof_measurement_load(VALUE self, VALUE data)
{
    VALUE target = Qnil;
    VALUE parent = Qnil;
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

    cMeasurement = rb_define_class_under(mProf, "Measurement", rb_cObject);
    rb_undef_method(CLASS_OF(cMeasurement), "new");
    rb_define_alloc_func(cMeasurement, prof_measurement_allocate);

    rb_define_method(cMeasurement, "called", prof_measurement_called, 0);
    rb_define_method(cMeasurement, "called=", prof_measurement_set_called, 1);
    rb_define_method(cMeasurement, "total_time", prof_measurement_total_time, 0);
    rb_define_method(cMeasurement, "add_total_time", prof_measurement_add_total_time, 1);
    rb_define_method(cMeasurement, "self_time", prof_measurement_self_time, 0);
    rb_define_method(cMeasurement, "add_self_time", prof_measurement_add_self_time, 1);
    rb_define_method(cMeasurement, "wait_time", prof_measurement_wait_time, 0);
    rb_define_method(cMeasurement, "add_wait_time", prof_measurement_add_wait_time, 1);

    rb_define_method(cMeasurement, "_dump_data", prof_measurement_dump, 0);
    rb_define_method(cMeasurement, "_load_data", prof_measurement_load, 1);
}
