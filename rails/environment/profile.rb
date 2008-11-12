# Settings specified here will take precedence over those in config/environment.rb
# The profile environment should match the same settings
# as the production environment to give a reasonalbe
# approximation of performance.  However, it should
# definitely not use the production databse!


# Cache classes - otherwise your code 
# will run approximately 5 times slower and the
# profiling results will be overwhelmed by Rails
# dependency loading mechanism
config.cache_classes = true

# Don't check template timestamps - once again this
# is to avoid IO times overwhelming profile results
config.action_view.cache_template_loading            = true

# This is debatable, but turn off action controller
# caching to see how long it really takes to run
# queries and render templates
config.action_controller.perform_caching             = false

# Turn off most logging
config.log_level = :info