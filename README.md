# Stateful

Stateful is inspired by event machine....I think...

It was an old library (> 5 years) converted to gem to facilitate state transfer of a record from one to another. 

Idea is to have different chained state and its associated action that causes the state changed.

For example, in real world visualization, an user account's status can be seen from
```
         (event: activate)
active -------------------->>> inactive
       <<<--------------------
         (event: inactivate)
```

Hence the activate event/action will cause the user state changed from active to inactive and inactivate event/action shall cause the user state changed from inactive to active.

The major usage of this gem is now at the view of the rails application, the developer shall know what is the next possible action that could display to the user. 
Now system can prompt user "inactivate user" instead of edit screen via "change status" link and select another status from the list.


## Usage
Stateful tied to ActiveRecord. In order to use:

```ruby
class User < ApplicationRecord
	# Indicate that stateful gem to be used. With initial status set to "active" (:active.to_s)
	stateful initial: :active

	# transform is state transfer specification, from state :active to :inactive
	transform :active => :inactive do
		# forward means from :active to :inactive, the event name is "inactive"
		forward :inactivate
		# backward means from :inactive to :active, the event name is "active"
		backward :activate
	end

	# if there are other state transfer specification, can add more...
	
end
```
Noted however that the database field used by the stateful is 'state' (string field).

Once the model is activated with stateful, it can be changed its state by invoking the appropriate event/action by invoking the event name with exclamation mark

```ruby
@model.<event/action name>!
```
or
```ruby
@model.send "#{<event/action name>}!"
```

Example to change the status from "active" to "inactive"
```ruby
@model.inactivate!
```

In the event that the action is not actually the next possible action, the status remained untouched and false shall be returned.
 

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'stateful'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install stateful
```

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
