# Reorm

A (possibly naive) ORM for use with the RethinkDB driver for Ruby. The library
is heavily influenced by the implementations of the active record pattern from
the Sequel and ActiveRecord libraries. I'm not 100% sure that this is a good
match for a document oriented store such as RethinkDB but here it is anyway.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reorm'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reorm

## Usage

First things first, the library needs to be configured to connect to your
RethinkDB instance. The simplest way to do this is create a file called
database.yml in the current working directory. Place content like the following
into this file...

    defaults: &defaults
      host: localhost
      port: 28015

    development:
      <<: *defaults
      db: reorm_dev

    test:
      <<: *defaults
      db: reorm_test

This will be picked up by the library and used to create a connection based on
it current environment (this defaults to development but if you set either the
RAILS_ENV or RACK_ENV environment variables that will be used instead). The
example above connects to the same RethinkDB instance, on localhost at port
28015, and then defaults the database it will use based on the enviornment
setting. Note the configuration options are more complicated and flexible than
using this approach but more on that later.

Next, declare a model class like so...

    class MyModel < Reorm::Model
    end

This small amount of code declares a class that will expect to save its data
elements into a table called my_models (it will create this table if it does not
already exist) and with an assumption that it uses a primary key called id. You
can change the table name used like so...

    class MyModel < Reorm::Model
      table_name "other_records"
    end

You could now create an instance of your model and save it to the database like
so...

    model = MyModel.create(one: 1, two: 2, three: {four: 4})

Once a model has been created like this it will have all of the top level fields
specified as parameters available as properties from the model object generated.
So, for example, you could access some of the value from the object created
above in code as follows...

    model.one   # = 1
    model.two   # = 2
    model.three # = {four: 4}

When an object is created it will automatically have its primary key filled out
by RethinkDB. By default models use a primary key called id but you can change
this by adding code like the following to you class declaration...

    primary_key :my_key

This will change the primary key used by the class to the field specified to
the call to ```primary_key```. When a primary key value has been generated by
RethinkDB its also available as a property from the object. Given the create
example above the models primary key can be accessed like any other property of
the object...

    model.id # RethinkDB generated primary key value.

To retrieve models back from the database you call either call the ```#all()```
method or use the ```#filter()``` method that is available on all model classes.
For example, if you had a model called User, you could use this code to iterate
across all user records...

    User.all.each do |user|
      # Do some stuff here.
      ...
    end

Or you could search for a user with a particular email address using code like
the following...

    user = User.filter({email: "user@email.com"}).first

If I wanted all users whose email address had a particular domain then I would
use code like the following...

    users = User.filter {|record| record["email"].match("@gmail.com$")}
    users.each do |user|
      # Do some stuff here.
      ...
    end

Note that in the predicate passed to the filter method the value passed to the
block is the raw record and not an instance of the model class. This means that
you have to dereference field values as you would from a Hash. When using the
output of the filter however you will receive model class instances and can
use those as normal.

The filter code is based on the RethinkDB filter functionality so consult the
documentation for more information.

### Validations

Model classes can provide functionality that allows them to be validated to
ensure that their data settings are consistent. To do this implement a method on
your class called ```#validate()```. The first thing to do in this method is to
make a call to the parent class implementation of this method via a call to
```super``` - this is important so don't forget to do it! After that you can
perform tests on the objects settings and add errors to the model where you
discover discrepancies. For example...

    def validate
      super
      if [nil, ""].include?(email)
        errors.add(:email, "cannot be blank.")
      end
    end

The library provides a number of helper method to shortcut some common
validations such as the following...

    def validate
      super
      validate_presence_of :email
    end

Would do the same thing as the first version of the ```validate()``` method
shown above. Some other examples include...

    def validate
      super
      validate_length_of :field1, minimum: 5, maximum: 20
      validate_inclusion_of :field2, "One", "Of", "These", "Values"
      validate_exclusion_of :field3 "Not", "One", "Of", "These"
    end

If you call te ```valid?()``` method on a model then the model object will be
validated and this method will return true if no errors were set and false if at
least one error was set. You can view the errors for a model by accessing its
```errors``` property which returns an instance of the
```Reorm::Reorm::PropertyErrors``` class.

Note that a object is automatically validated any time it is saved and that the
save request will fail if the object fails validation and an exception will be
raised. You can turn validation off for a save by passing false as a parameter
to the save call.

### Event Callbacks

The library supports a number of event related callbacks that will be invoked
when a specific event occurs. You can add an event related callback to a model
by declaring it within the model class like so...

    before_save :method_name

In this case the library will attempt to invoked a method called ```method_name```
on the model object after validation but before the object is actually written
to RethinkDB. Note the method has to actually exist on the model for this to
work. The following callbacks, in the order in which they occur, are available -
before_validate, after_validate, before_create, before_update, before_save,
after_save, after_update and after_create.

### Unit Tests

To run the unit tests you'll need a locally running instance of RethinkDB (none
of that nonsense mocking out DB writes rubbish here!) and then you can run the
available unit tests using the ```rspec``` command.

### Configuration

The library, on load up, looks for a file containing the RethinkDB configuration
details. It will settle upon the first file that it finds called database.yml,
rethinkdb.yml or application.yml (note a .json extension is also acceptable).
This file will be expected to contain a Hash in the appropriate format. Within
this Hash it will first look for a an environment base entry (i.e. a key of
'development', 'production' or 'test'). If it finds no such key it will assume
that the entire Hash is the configuration, otherwise it will extract the entry
under the given key and use that as configuration.

Next it takes the output from the previous section and looks for an entry keyed
under 'rethinkdb'. Again, if it does not find it, it will assume the entire
entry is its configuration, otherwise it will focus down on the keyed entry
once more. The reasoning here is to allow you to have a separate standalone
database configuration file or to allow your database configuration values to
be part of a larger configuration file. The output from this process is expected
to be the parmaeters that will allow the library to connect to a RethinkDB
server.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/reorm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
