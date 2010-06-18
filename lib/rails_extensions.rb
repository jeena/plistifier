require "cfpropertylist/rbCFPropertyList"

class Array
  def to_plist(options = {})
    options[:plist_format] ||= CFPropertyList::List::FORMAT_BINARY 
    
    array = []
    self.each do |a|
      if a.is_a? ActiveRecord::Base
        array << a.to_hash(options)
      else
        array << a
      end
    end
    
    plist = CFPropertyList::List.new
    plist.value = CFPropertyList.guess(array, :convert_unknown_to_string => true)
    plist.to_str(options[:plist_format])
  end  
end

module ActionController
  class Base
    def render_with_plist(options = nil, extra_options = {}, &block)
      
      plist = nil
      plist = options[:plist] unless options.nil?
      
      if plist
     
        if options[:plist_filename].blank?
          if plist.is_a? Array
            filename = plist.first.class.name.pluralize + ".plist"     
          else
            filename = "#{plist.class.name}-#{plist.id}.plist"
          end
        else
          filename = options[:plist_filename]
        end
        
        send_data(
          plist.to_plist(options),
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