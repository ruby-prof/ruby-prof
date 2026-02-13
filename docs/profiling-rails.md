# Profiling Rails

To profile a Rails application it is vital to run it using production-like settings (cache classes, cache view lookups, etc.). Otherwise, Rails dependency loading code will overwhelm any time spent in the application itself (our tests show that Rails dependency loading causes a roughly 6x slowdown). The best way to do this is to create a new Rails environment, `profile`.

To profile Rails:

1. Add ruby-prof to your Gemfile:

   ```ruby
   group :profile do
     gem 'ruby-prof'
   end
   ```

   Then install it:

   ```bash
   bundle install
   ```

2. Create `config/environments/profile.rb` with production-like settings and the ruby-prof middleware:

   ```ruby
   # config/environments/profile.rb
   require_relative "production"

   Rails.application.configure do
     # Optional: reduce noise while profiling.
     config.log_level = :warn

     # Optional: disable controller/view caching if you want raw app execution timing.
     config.action_controller.perform_caching = false

     config.middleware.use Rack::RubyProf, path: Rails.root.join("tmp/profile")
   end
   ```

   By default the rack adapter generates flat text, graph text, graph HTML, and call stack HTML reports.

3. Start Rails in the profile environment:

   ```bash
   bin/rails server -e profile
   ```

   You can run a console in the same environment with:

   ```bash
   bin/rails console -e profile
   ```

4. Make a request to generate profile output:

   ```bash
   curl http://127.0.0.1:3000/
   ```

5. Inspect reports in `tmp/profile`:

   ```bash
   ls -1 tmp/profile
   ```

   Reports are generated per request path. Repeating the same request path overwrites the previous report files for that path.
