#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class AbstractPrinterTest < TestCase
  def setup
    @result = {}
    @printer = RubyProf::AbstractPrinter.new(@result)
    @options = {}
    @printer.setup_options(@options)
  end

  def test_editor_uri
    env = {}

    with_const_stubbed('ENV', env) do
      @options[:editor_uri] = 'nvim'

      env['RUBY_PROF_EDITOR_URI'] = 'atm'
      assert_equal('atm', @printer.editor_uri)

      env['RUBY_PROF_EDITOR_URI'] = nil
      assert_equal(false, @printer.editor_uri)

      env.delete('RUBY_PROF_EDITOR_URI')
      assert_equal('nvim', @printer.editor_uri)

      with_const_stubbed('RUBY_PLATFORM', 'x86_64-darwin18') do
        assert_equal('nvim', @printer.editor_uri)

        @options.delete(:editor_uri)
        assert_equal('txmt', @printer.editor_uri)
      end
      with_const_stubbed('RUBY_PLATFORM', 'windows') do
        assert_equal(false, @printer.editor_uri)
      end
    end
  end

  private

  def with_const_stubbed(name, value)
    old_verbose, $VERBOSE = $VERBOSE, nil
    old_value = Object.const_get(name)

    Object.const_set(name, value)
    yield
    Object.const_set(name, old_value)

    $VERBOSE = old_verbose
  end
end
