require "cfpropertylist/rbCFPropertyList"

module ActionController
  class Base
    def render_with_plist(options = nil, extra_options = {}, &block)
      
      plist = options.delete(:plist) unless options.nil?

      if plist
        
        unless filename = options.delete(:plist_filename)
          if plist.is_a? Array
            filename = plist.first.class.name.pluralize + ".plist"
          elsif plist.respond_to?(:id)
            filename = "#{plist.class.name}-#{plist.id}.plist"
          else
            filename = "#{plist.class.name}-data.plist"
          end
        end

        unless options.nil?
          if plist.is_a? Array
            plist.each do |entry|
              if entry.respond_to? :plist_item_options=
                entry.plist_item_options = options
              end
            end
          end
        end
        
        plist_options = {
          :converter_method => :to_plist_item,
          :convert_unknown_to_string => true
        }

        data = plist.is_a?(CFPropertyList::List) ? plist : plist.to_plist(plist_options)
        
        send_data(
          data,
          :type => Mime::PLIST, 
          :filename => filename, 
          :disposition => 'inline'
        )

      else
        render_without_plist(options, extra_options, &block) 
      end
    end
    
    alias_method_chain :render, :plist
  end
end