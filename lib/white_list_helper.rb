module WhiteListHelper
  
  @@white_lister ||= WhiteLister.new

  klass = class << self; self; end
  klass_methods = []
  inst_methods  = []
  [:bad_tags, :tags, :attributes, :protocols].each do |attr|
    # Add class methods to the module itself
    klass_methods << <<-EOS
      def #{attr}=(value) @@white_lister.instance_variable_set(:@#{attr}, Set.new(value)) end
      def #{attr}() @@white_lister.instance_variable_get(:@#{attr}) end
    EOS
    
    # prefix the instance methods with white_listed_*
    inst_methods << "def white_listed_#{attr}() ::WhiteListHelper.#{attr} end"
  end
  
  klass.class_eval klass_methods.join("\n"), __FILE__, __LINE__
  class_eval       inst_methods.join("\n"),  __FILE__, __LINE__

  # This White Listing helper will html encode all tags and strip all attributes that aren't specifically allowed.  
  # It also strips href/src tags with invalid protocols, like javascript: especially.  It does its best to counter any
  # tricks that hackers may use, like throwing in unicode/ascii/hex values to get past the javascript: filters.  Check out
  # the extensive test suite.
  #
  #   <%= white_list @article.body %>
  # 
  # You can add or remove tags/attributes if you want to customize it a bit.
  # 
  # Add table tags
  #   
  #   WhiteListHelper.tags.merge %w(table td th)
  # 
  # Remove tags
  #   
  #   WhiteListHelper.tags.delete 'div'
  # 
  # Change allowed attributes
  # 
  #   WhiteListHelper.attributes.merge %w(id class style)
  # 
  # white_list accepts a block for custom tag escaping.  Shown below is the default block that white_list uses if none is given.
  # The block is called for all bad tags, and every text node.  node is an instance of HTML::Node (either HTML::Tag or HTML::Text).  
  # bad is nil for text nodes inside good tags, or is the tag name of the bad tag.  
  # 
  #   <%= white_list(@article.body) { |node, bad| white_listed_bad_tags.include?(bad) ? nil : node.to_s.gsub(/</, '&lt;') } %>
  #
  def white_list(*args, &blk)
    @@white_lister.white_list(*args, &blk)
  end
  
  protected
  
    def contains_bad_protocols?(value)
      @@white_lister.send(:contains_bad_protocols?, value)
    end
end