[![Build Status](https://travis-ci.org/lokalportal/chain_options.svg?branch=master)](https://travis-ci.org/lokalportal/chain_options)
[![Maintainability](https://api.codeclimate.com/v1/badges/aa9c3e9eb2a02095c587/maintainability)](https://codeclimate.com/github/lokalportal/chain_options/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/aa9c3e9eb2a02095c587/test_coverage)](https://codeclimate.com/github/lokalportal/chain_options/test_coverage)

# ChainOptions

ChainOptions is a small gem which allows you to add non-destructive chainable options to
your classes. It is useful to incrementally build instances without overriding the previous
one and provides an easy-to-understand DSL to set options either through 
method-chaining or in a block.

An example:

```ruby
class MyItemFeed
  include ChainOptions::Integration
  
  chain_option :page, 
               default: 1, 
               invalid: :default, 
               validate: ->(value) { value.to_i.positive? }
  
  chain_option :per_page,
               default:  30,
               validate: ->(value) { value.to_i.positive? },
               invalid:  :default
end

feed = MyItemFeed.new.build_options do
  set :page, params[:page]
  set :per_page, params[:per_page]
end

# or

feed = MyItemFeed.new.page(params[:page]).per_page(params[:per_page])
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chain_options'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chain_options

## Usage

To use ChainOptions in one of your classes, simply include its integration module:

```ruby
include ChainOptions::Integration
```

Afterwards, you're ready to define the options available to instances of your class.

### Basic Options

The easiest way to define an option is to call `chain_option` with just the option name:

```ruby
class MyClass
  chain_option :my_option
end
```

This will generate the method `#my_option` which is accessible by instances of your class.
When it's called with an argument, it will return a new instance of your class with 
the option set to this value, when being called without an argument, it will return the current value.

```ruby
my_class = MyClass.new #=> Instance 1 of MyClass
my_class.my_option('my value') #=> Instance 2 of MyClass
my_class.my_option #=> 'my value'
``` 

Please note that instance variables are currently not carried over to the new
instances built when setting a new option.  
This decision was made to ensure no cached values could be used any more
after changing an option value:

```ruby
class Feed
  chain_option :page
  chain_option :per_page
  
  def entries
    @entries ||= MyModel.page(page).per(per_page)
  end
end
```

Setting `page` to a different value after `#entries` was called once would not  
lead to another page being loaded, the return value would stay the same.

This behaviour might be changed in the future, but would only make the gem more complex
for now.

Array may be passed in as multiple arguments or an Array object, so the following calls are equivalent:

```ruby
my_object.my_value(1, 2, 3)
my_option.my_value([1, 2, 3])
```

### Advanced Options

#### Filters

It is possible to apply filters to option values. As soon as a filter Proc is defined,
it is assumed that the option value will be an Array.

```ruby
chain_option :my_even_numbers,
             filter: -> (number) { number.even? }
             
my_object.my_even_numbers(1, 2, 3, 4, 5) #=> [2, 4]
```

**Note**: As soon as `:filter` is defined, the value will be treated as Array, even if only a single
element is passed in:

```ruby
my_object.my_even_numbers(2) #=> [2]
```

#### Value Validations

It is possible to define validations on the setting value. These are executed whenever a new
value is set and will either cause an Exception or the option going back to the default value:

```ruby
chain_option :per_page,
             validate: -> (value) { value.to_i.positive? },
             invalid: :raise
```

The above example ensures that a value set for the `per_page` option has to be positive.
Otherwise, an `ArgumentError` is raised.

```ruby
chain_option :per_page,
             default: 1
             validate: -> (value) { value.to_i.positive? },
             invalid: :default
             
my_object.per_page(-1).per_page #=> 1 
```

**Note**: If filters are set up as well, your validation proc will always receive an Array, never a single element.

#### Value Transformations

It is possible to perform automatic transformations (or type casts) on an option value, 
pretty similar to what ActiveRecord does when e.g. a numeric value is assigned to a string attribute.

As options don't have a type, you have to define the transformation yourself: 

```ruby
chain_option :my_strings,
             transform: -> (element) { element.to_s }
             
chain_option :my_strings,
             transform: :to_s
```

The above calls are equivalent. If a symbol is given, the value (resp. each element of it in case of
an Array) is expected to respond to a method with the same name.

If the value is an array, the `transform` Proc will receive each item individually.

#### Default Values

It is possible to specify a default value for each option using the `:default` keyword argument.
The default value is returned in the following cases:

* No custom value was set for the option yet
* The value set for the option is invalid and the option is set to use the default value instead (see below)

The default value may either be a Proc which is executed on demand or any kind of Ruby object.

```ruby
chain_option :per_page,
             default: -> { SomeStore.get_default_per_page }
```

#### Incremental Values

Options can be set to increment their value through multiple setter calls:

```ruby
chain_option :favourite_books, incremental: true

user.favourite_books('Lord of the Rings').favourite_books('The Hobbit')
#=> [['Lord of the Rings'], ['The Hobbit]]
```

As the values should still be separateable, the elements which were added in each
setter call are wrapped in another array instead of just appending them to the collection.
Otherwise, it wouldn't be possible to determine that the following value was caused by two sets:

```ruby
user.favourite_books('Momo', 'Neverending Story').favourite_books('Lord of the Rings', 'The Hobbit')
#=> [["Momo", "Neverending Story"], ["Lord of the Rings", "The Hobbit"]]
```

#### Blocks as option values

If your option accepts blocks as values, setting this to `true` allows you to use the block syntax
to set a new option value instead of having to pass in a lambda function or Proc object:

```ruby
chain_option :my_proc, allow_block: true

my_object = my_object.my_proc do
  # ...
end

my_object.my_proc #=> <#Proc...>
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lokalportal/chain_options.  
For pull request, please follow [git-flow](https://danielkummer.github.io/git-flow-cheatsheet/) naming conventions.  
 
This project is intended to be a safe, welcoming space for collaboration, 
and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ChainOptions project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/chain_options/blob/master/CODE_OF_CONDUCT.md).
