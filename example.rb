module EnableSwitch
  module ClassMethods
    attr_accessor :class_enabled

    def enable_switch_methods(*methods_to_add)
      @_enable_switch_methods ||= []
      @_enable_switch_methods = :all if methods_to_add == :all || methods_to_add.length.zero?
      @_enable_switch_methods.concat(methods_to_add)
    end

    def method_added(added_method)
      # don't double wrap a method
      @_enable_added_to ||= []
      return if @_enable_added_to.include?(added_method)

      # don't wrap an unspecified method if methods were specified
      return if defined?(@_enable_switch_methods) && @_enable_switch_methods != :all && !@_enable_switch_methods.include?(added_method)
      @_enable_added_to << added_method

      # wrapping the message
      m = self.instance_method(added_method)
      define_method(added_method) do |*args, &block|
        return unless @enabled && self.class.class_enabled
        m.bind(self).(*args, &block)
      end
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
    klass.instance_variable_set(:@class_enabled, true)
  end

  attr_accessor :enabled

  def initialize(*args, &block)
    @enabled = true
    super
  end
end

class Foo
  include EnableSwitch
  enable_switch_methods :puts_method

  def puts_method(str)
    puts str
  end

  def add(val1, val2)
    puts(val1 + val2)
  end
end

if __FILE__ == $0
  f1 = Foo.new
  f2 = Foo.new
  f1.enabled = false

  f1.puts_method("Not enabled")
  f2.puts_method("Enabled")
  f1.add(1, 2)
  f2.add(3, 4)

  Foo.class_enabled = false

  f1.puts_method("Not enabled 2")
  f2.puts_method("Enabled 2")
  f1.add(5, 6)
  f2.add(7, 8)
end
