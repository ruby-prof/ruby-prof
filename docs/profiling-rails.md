# Profiling Rails

To profile a Rails application it is vital to run it using production like settings (cache classes, cache view lookups, etc.). Otherwise, Rail's dependency loading code will overwhelm any time spent in the application itself (our tests show that Rails dependency loading causes a roughly 6x slowdown). The best way to do this is create a new Rails environment, profile.rb.

To profile Rails:

1. Create a new profile.rb environment. Make sure to turn on `cache_classes` and `cache_template_loading`. Otherwise your profiling results will be overwhelmed by the time Rails spends loading required files. You should likely turn off caching.

2. Add the ruby-prof to your gemfile:

   ```ruby
   group :profile do
     gem 'ruby-prof'
   end
   ```

3. Add the ruby prof rack adapter to your middleware stack. The Rails [documentation](https://guides.rubyonrails.org/configuring.html#configuring-middleware) describes several ways to do this. One way is to add the following code to `application.rb`:

   ```ruby
   if Rails.env.profile?
     config.middleware.use Rack::RubyProf, path: './tmp/profile'
   end
   ```

   The path is where you want profiling results to be stored. By default the rack adapter will generate flat text, graph text, graph HTML, and call stack HTML reports.

4. Now make a request to your running server. New profiling information will be generated for each request. Note that each request will overwrite the profiling reports created by the previous request!
