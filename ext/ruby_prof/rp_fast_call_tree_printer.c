#include "ruby_prof.h"
#include "math.h"

VALUE cFastCallTreePrinter;
static ID id_addstr;

/* Utility struct to mirror the require ivars in the ruby class.

    output is a ruby IO object

    value_scale is the conversion factor used to scale the result for rounding.
    This is set based on the measure mode. */
typedef struct call_tree_printer_vars
{
    VALUE output;
    size_t len;
    double value_scales[];
} call_tree_printer_vars;

static call_tree_printer_vars *
call_tree_printer_vars_allocate(size_t len)
{
    call_tree_printer_vars *result =
      (call_tree_printer_vars*) ruby_xmalloc(
          sizeof(call_tree_printer_vars) + len * sizeof(double));
    result->len = len;
    return result;
}

/* Converts the recorded value to a fixed point number based on value scale */
static long int
convert(double value, double value_scale)
{
    return lround(value * value_scale);
}

static VALUE
addstr(VALUE io, VALUE str)
{
    return rb_funcall(io, id_addstr, 1, str);
}

static void
print_header(
    call_tree_printer_vars *vars,
    prof_method_t *method,
    char *name)
{
    /* Format is file and method name followed by line and self time */
    addstr(
        vars->output,
        rb_sprintf(
            "fl=%s\nfn=%s\n%d",
            prof_method_t_source_file(method),
            name,
            method->line));
}

/* Returns the index of the callee in the call_infos list. */
static int
call_info_index(prof_call_infos_t *call_infos, prof_call_info_t *callee)
{
    prof_call_info_t **i;
    for (i = call_infos->start; i < call_infos->ptr; i++) {
        if ((*i) == callee) {
            return i - call_infos->start;
        }
    }

    return -1;
}

static void
print_child(call_tree_printer_vars *vars, prof_call_info_t *callee)
{
    prof_method_t *target = callee->target;
    VALUE name = prof_method_t_calltree_name(target);

    if (target->recursive) {
        int index = call_info_index(target->call_infos, callee);
        name = rb_sprintf("%s [%d]", RSTRING_PTR(name), index);
    }

    addstr(
        vars->output,
        rb_sprintf(
            "cfl=%s\ncfn=%s\ncalls=%d %d\n%d",
            prof_method_t_source_file(target),
            RSTRING_PTR(name),
            callee->called,
            callee->line,
            callee->line));

    for(size_t i = 0; i < callee->measures_len; i++) {
        addstr(
            vars->output,
            rb_sprintf(
                " %ld",
                convert(callee->measure_values[i].total, vars->value_scales[i])));
    }
    addstr(vars->output, rb_str_new2("\n"));

    RB_GC_GUARD(name);
}

/* Function to be called by st_foreach to print each child call info */
static int
print_child_iter(st_data_t key, st_data_t value, st_data_t vars)
{
    print_child((call_tree_printer_vars *) vars, (prof_call_info_t *) value);
    return ST_CONTINUE;
}

static void
print_simple_method(call_tree_printer_vars *vars, prof_method_t *method)
{
    VALUE calltree_name = prof_method_t_calltree_name(method);
    size_t measures_len = (*method->call_infos->start)->measures_len;

    print_header(vars, method, RSTRING_PTR(calltree_name));
    for(size_t j = 0; j < measures_len; j++) {
        addstr(vars->output,
              rb_sprintf(" %ld", convert(prof_method_t_self_time(method, j), vars->value_scales[j])));
    }
    addstr(vars->output, rb_str_new2("\n"));

    prof_call_info_t **i;
    for(i = method->call_infos->start; i < method->call_infos->ptr; i++) {
        st_foreach((*i)->call_infos, print_child_iter, (uintptr_t) vars);
    }

    RB_GC_GUARD(calltree_name);
}

static void
print_recursive_method(call_tree_printer_vars *vars, prof_method_t *method)
{
    VALUE calltree_name = prof_method_t_calltree_name(method);

    prof_call_info_t **i;
    for(i = method->call_infos->start; i < method->call_infos->ptr; i++) {
        int index = i - method->call_infos->start;
        VALUE name = rb_sprintf("%s [%d]", RSTRING_PTR(calltree_name), index);

        print_header(vars, method, RSTRING_PTR(name));
        for(size_t j = 0; j < (*i)->measures_len; j++) {
            addstr(vars->output,
                   rb_sprintf(" %ld", convert((*i)->measure_values[j].self, vars->value_scales[j])));
        }
        addstr(vars->output, rb_str_new2("\n"));

        st_foreach((*i)->call_infos, print_child_iter, (uintptr_t) vars);

        RB_GC_GUARD(name);
    }

    RB_GC_GUARD(calltree_name);
}

static int
print_method(call_tree_printer_vars *vars, prof_method_t *method)
{
    if(!method->excluded) {
        if (method->recursive) {
            print_recursive_method(vars, method);
        } else {
            print_simple_method(vars, method);
        }

        addstr(vars->output, rb_str_new2("\n"));
    }

    return ST_CONTINUE;
}

/* Iterator to handle reversing an st_table of methods into a provided array */
static int
reverse_methods(st_data_t key, st_data_t value, st_data_t arg)
{
    prof_method_t ***methods = (prof_method_t ***) arg;

    prof_method_t *method = (prof_method_t *) value;

    *methods = *methods - 1;
    **methods = method;

    return ST_CONTINUE;
}

static void
print_methods_in_reverse(call_tree_printer_vars *vars, st_table *method_table)
{
    st_index_t num_entries = method_table->num_entries;

    prof_method_t **reversed = ALLOC_N(prof_method_t*, num_entries);
    prof_method_t **end = reversed + num_entries;

    prof_method_t **iterator = end;

    st_foreach(method_table, reverse_methods, (uintptr_t) &iterator);

    prof_method_t **i;
    for(i = reversed; i < end; i++) {
        print_method(vars, *i);
    }

    xfree(reversed);
}


/* call-seq:
   print_thread(thread) -> nil

   Prints to @output the call tree of a thread
*/
VALUE
prof_fast_call_tree_printer_print_thread(VALUE self, VALUE thread) {
    thread_data_t *thread_data = prof_get_thread(thread);

    VALUE output = rb_iv_get(self, "@output");
    VALUE value_scales_val = rb_iv_get(self, "@value_scales");

    Check_Type(value_scales_val, T_ARRAY);
    size_t value_scales_len = RARRAY_LEN(value_scales_val);

    call_tree_printer_vars *vars = call_tree_printer_vars_allocate(value_scales_len);
    vars->output = output;
    for(size_t i = 0; i < value_scales_len; i++) {
        vars->value_scales[i] = NUM2DBL(rb_ary_entry(value_scales_val, i));
    }

    print_methods_in_reverse(vars, thread_data->method_table);

    xfree(vars);

    return Qnil;
}

void rp_init_fast_call_tree_printer()
{
    id_addstr = rb_intern("<<");

    cFastCallTreePrinter = rb_define_class_under(mProf,
            "FastCallTreePrinter", rb_cObject);
    rb_define_method(cFastCallTreePrinter, "print_thread",
            prof_fast_call_tree_printer_print_thread, 1);
}
