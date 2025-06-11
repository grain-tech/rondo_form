module RondoForm
  module ViewHelpers

    # this will show a link to remove the current association. This should be placed inside the partial.
    # either you give
    # - *name* : the text of the link
    # - *f* : the form this link should be placed in
    # - *html_options*:  html options to be passed to link_to (see <tt>link_to</tt>)
    #
    # or you use the form without *name* with a *&block*
    # - *f* : the form this link should be placed in
    # - *html_options*:  html options to be passed to link_to (see <tt>link_to</tt>)
    # - *&block*:        the output of the block will be show in the link, see <tt>link_to</tt>

    def link_to_remove_association(*args, &block)
      if block_given?
        f            = args.first
        html_options = args.second || {}
        name         = capture(&block)
        link_to_remove_association(name, f, html_options)
      else
        name, f, html_options = *args
        html_options ||= {}

        is_dynamic = f.object.new_record?
        html_options[:class] = [html_options[:class], "remove_fields #{is_dynamic ? 'dynamic' : 'existing'}"].compact.join(' ')
        html_options[:'data-action'] = "click->nested-rondo#removeField"
        f.hidden_field(:_destroy) + link_to(name, '', html_options)
      end
    end

    # shows a link that will allow to dynamically add a new associated object.
    #
    # - *name* :               the text to show in the link
    # - *f* :                  the form this should come in
    # - *association* :        the associated objects, e.g. :tasks, this should be the name of the <tt>has_many</tt> relation.
    # - *render_options*:      options to be passed to <tt>render</tt>
    #   - partial: 'file_name' (for traditional partial rendering)
    #   - component: ComponentClass (for Phlex component rendering)
    #   - locals: { hash_of: 'local variables for rendered partial/component' }
    #   - build_object: Proc to customize object initialization
    #   - object_params: Hash of attributes to set on the new object
    #   - discriminator_field: field name for STI discrimination
    #   - discriminator_value: value for STI discrimination
    #   - template_id: custom template element ID
    # - *html_options*:     html options to be passed to <tt>link_to</tt> (see <tt>link_to</tt>)
    # - *&block*:              see <tt>link_to</tt>

    def link_to_add_association(*args, &block)
      if block_given?
        f, association, render_options, html_options = *args
        render_options ||= {}
        html_options ||= {}
        link_to_add_association(capture(&block), f, association, render_options, html_options)
      else
        name, f, association, render_options, html_options = *args
        render_options ||= {}
        html_options ||= {}

        html_options[:class] = [html_options[:class], "add_fields"].compact.join(' ')
        html_options[:'data-association'] = association.to_s.singularize
        html_options[:'data-associations'] = association.to_s.pluralize
        html_options[:'data-action'] = "click->nested-rondo#addField"

        # Support for custom object initialization
        if render_options[:build_object].is_a?(Proc)
          new_object = render_options[:build_object].call(f.object)
        else
          new_object = f.object.class.reflect_on_association(association).klass.new
        end
        
        # Allow discriminator values to be set
        if render_options[:object_params].is_a?(Hash)
          render_options[:object_params].each do |key, value|
            new_object.send("#{key}=", value) if new_object.respond_to?("#{key}=")
          end
        end
        
        model_name = new_object.class.name.underscore
        template_id = render_options[:template_id] || "#{model_name}_fields_template"
        
        # Store discriminator data in template for JavaScript access
        template_data = {'nested-rondo_target': 'template'}
        if render_options[:discriminator_field]
          template_data['discriminator-field'] = render_options[:discriminator_field]
          template_data['discriminator-value'] = render_options[:discriminator_value]
        end
        
        hidden_div = content_tag("template", id: template_id, data: template_data) do
          render_association(association, f, new_object, render_options)
        end
        hidden_div.html_safe + link_to(name, '', html_options )
      end
    end

    # :nodoc:
    def render_association(association, f, new_object, render_options)
      locals = render_options.delete(:locals) || {}
      
      # Check if a component class is provided
      if render_options[:component]
        output = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
          # Instantiate and render the Phlex component
          component_class = render_options[:component]
          component_instance = component_class.new(
            form_builder: builder,
            component: new_object,
            **locals
          )
          # Render the component to HTML string
          if component_instance.respond_to?(:call)
            # For Phlex components
            component_instance.call
          else
            # Fallback for other component frameworks
            component_instance.to_s
          end
        end
        output
      else
        # Fallback to partial rendering for backward compatibility
        render_options[:partial] = "#{association.to_s.singularize}_fields" unless render_options[:partial]
        f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
          locals.store(:f, builder)
          render(render_options[:partial], locals)
        end
      end
    end
  end
end
