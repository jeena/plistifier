module ActionController
  class Base
    def render_with_plist(options = nil, extra_options = {}, &block)
      
      plist = options.delete(:plist) unless options.nil?

      if plist
        
        response.headers["Location"] = options[:location] unless options[:location].blank?
        options[:content_type] ||= Mime::PLIST
        options[:disposition] ||= "inline"

        if options[:plist_filename].blank?
          if plist.is_a? Array
            options[:plist_filename] = plist.first.class.name.pluralize + ".plist"
          elsif plist.respond_to?(:id)
            options[:plist_filename] = "#{plist.class.name}-#{plist.id}.plist"
          else
            options[:plist_filename] = "#{plist.class.name}-data.plist"
          end
        end

        if plist.is_a? Array
          plist.each do |entry|
            if entry.respond_to? :plist_item_options=
              entry.plist_item_options = options
            end
          end
        end

        data = plist
        unless plist.is_a?(CFPropertyList::List)
          plist_options = {
            :converter_method => :to_plist_item,
            :convert_unknown_to_string => true
          }
          data = plist.to_plist(plist_options)
        end

        send_data(
          data,
          :type => options[:content_type], 
          :filename => options[:plist_filename], 
          :disposition => options[:disposition],
          :status => options[:status]
        )

      else
        render_without_plist(options, extra_options, &block) 
      end
    end
    
    alias_method_chain :render, :plist
  end
end
