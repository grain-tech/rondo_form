# RondoForm

Handle dynamic nested forms, same as Cocoon, but using StimulusJS

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rondo_form

Or inside the Gemfile add the following

    $ gem 'rondo_form', '~> 1.0'

Run the installation task:

    $ rails g rondo_form:install

## Usage

For example, you have `Project` model, which has `has_many` relationship with `Task` model:

```
rails g scaffold Project name:string description:string
rails g model Task description:string done:boolean project:belongs_to
```

You need to add `accepts_nested_attributes_for` to `Project` model:

```rb
class Project < ApplicationRecord
  has_many :tasks, dependent: :destroy
  accepts_nested_attributes_for :tasks, reject_if: :all_blank, allow_destroy: true
end
```

### Sample with SimpleForm

The RondoForm gem adds two helper functions: `link_to_add_association` and `link_to_remove_association`.
More details about two view helpers [here](#view-helpers).

The example below illustrates the way to use it.

In your `projects/_form` partial:

``` erb
<%= simple_form_for(@project) do |f| %>

  <div class="form-inputs">
    <%= f.input :name %>
    <%= f.input :description %>
  </div>

  <h3 class="text-xl mt-4">Tasks</h3>
  <div class="my-2" data-controller="nested-rondo" data-nested-rondo-field-class-value="task-field">
    <div data-nested-rondo-target="fieldContain">
      <%= f.simple_fields_for :tasks do |task| %>
        <%= render "task_fields", f: task %>
      <% end %>
    </div>
    <div class="links">
      <%= link_to_add_association "Add Task", f, :tasks %>
    </div>
  </div>

  <div class="form-actions mt-4">
    <%= f.button :submit %>
  </div>
<% end %>
```

In your `_task_fields` partial:

``` erb
<div class="task-field">
  <%= f.input :description %>
  <%= f.input :done, as: :boolean %>
  <%= link_to_remove_association "Remove Task", f %>
</div>
```

#### Controller

Using projects example, in your controller ProjectsController, your params method should look like:
``` ruby
def project_params
  params.require(:project).permit(:name, :description, tasks_attributes: [:description, :done, :_destroy, :id])
end
```

params `:_destroy` allow to delete tasks and `:id` allow to update tasks on update action

### Using Phlex Components

RondoForm supports using Phlex components instead of partials for rendering association fields. This is useful when you're using Phlex for your view layer.

#### Example with Phlex Component

First, create a Phlex component for your fields:

```ruby
# app/components/task_fields_component.rb
class TaskFieldsComponent < ApplicationComponent
  attr_reader :form_builder, :component

  def initialize(form_builder:, component:, **locals)
    @form_builder = form_builder
    @component = component
    @locals = locals
  end

  def template
    div(class: "task-field") do
      render form_builder.input(:description)
      render form_builder.input(:done, as: :boolean)
      render link_to_remove_association("Remove Task", form_builder)
    end
  end
end
```

Then use it in your form:

```erb
<%= link_to_add_association "Add Task", f, :tasks,
    render_options: {
      component: TaskFieldsComponent,
      locals: { some_option: true }
    }
%>
```

The component will receive:
- `form_builder`: The form builder for the association
- `component`: The new object instance
- Any additional locals passed in the `locals` hash

### Demo
View details implement for manual Rails form at this PR [dynamic nested form with rondo_form](https://github.com/hungle00/rails-opus/pull/15/files)

## View helpers

#### `link_to_add_association(name, form_builder, render_options, html_options, &block)`

### Signatures
```ruby
link_to_add_association(name, form_builder, render_options, html_options)
# Link text is passed in as name

link_to_add_association(form_builder, render_options, html_options, &block)
# Link text is passed in as a block
```

### Options
- `render_options: hash containing options for rendering` - Options for rendering the association fields:
  - `:partial` - Name of the partial to render (defaults to `{association}_fields`)
  - `:component` - Phlex component class to render instead of a partial
  - `:locals` - Hash of local variables to pass to the partial/component
  - `:build_object` - Proc to customize object initialization
  - `:object_params` - Hash of attributes to set on the new object
  - `:discriminator_field` - Field name for STI discrimination
  - `:discriminator_value` - Value for STI discrimination
  - `:template_id` - Custom template element ID

- `html_options: hash containing options for Rails' link_to helper` - This is passed to the Rails `link_to` helper to
provide the options that are desired when rendering your association fields. If no special requirements are needed,
can be passed as `nil` or and empty hash `{}`.

#### `link_to_remove_association(name, form_builder, html_options, &block)`

### Signatures
```ruby
link_to_remove_association(name, form_builder, html_options)
# Link text is passed in as name

link_to_remove_association(form_builder, html_options, &block)
# Link text is passed in as a block
```

### Options

- `html_options: hash containing options for Rails' link_to helper` - This is passed to the Rails `link_to` helper to
provide the options that are desired when rendering your association fields. If no special requirements are needed,
can be passed as `nil` or and empty hash `{}`.

## Stimulus convention
- I named Stimulus controller `nested-rondo`, feel free to change the name of `data-controller` to match your purpose
- `data-nested-rondo-target="fieldContain"` must be added to an element that wraps all nested fields, the new field will be appended to this element.
- `data-nested-rondo-field-class-value` is used to detect the element that needs to be removed. Its value must match the class name of an element that wraps the partial. If you do not declare it, it will default remove the closest parent element.
- The partial added when clicking `link_to_add_association` is named for the association name with the `_fields` suffix. In this example, the partial is named `task_fields`. You can change the partial name by passing the `partial_name` option to `link_to_add_association`.

**Import Maps**  
- If you use `importmap`. it auto loads eagerly all controllers defined in the import map under `controllers/**/*_controller`,
so you maybe don't need under code.
```js
import NestedRondoController from "./nested_rondo_controller"
lazyLoadControllersFrom("nested-rondo", NestedRondoController)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hungle00/rondo_form.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
