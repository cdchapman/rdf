module RDF
  ##
  # An RDF literal.
  #
  # @example Creating a plain literal
  #   value = RDF::Literal.new("Hello, world!")
  #   value.plain?                                   #=> true
  #
  # @example Creating a language-tagged literal (1)
  #   value = RDF::Literal.new("Hello!", :language => :en)
  #   value.has_language?                            #=> true
  #   value.language                                 #=> :en
  #
  # @example Creating a language-tagged literal (2)
  #   RDF::Literal.new("Wazup?", :language => :"en-US")
  #   RDF::Literal.new("Hej!",   :language => :sv)
  #   RDF::Literal.new("¡Hola!", :language => :es)
  #
  # @example Creating an explicitly datatyped literal
  #   value = RDF::Literal.new("2009-12-31", :datatype => RDF::XSD.date)
  #   value.has_datatype?                            #=> true
  #   value.datatype                                 #=> RDF::XSD.date
  #
  # @example Creating an implicitly datatyped literal
  #   value = RDF::Literal.new(Date.today)
  #   value.has_datatype?                            #=> true
  #   value.datatype                                 #=> RDF::XSD.date
  #
  # @example Creating implicitly datatyped literals
  #   RDF::Literal.new(false).datatype               #=> XSD.boolean
  #   RDF::Literal.new(true).datatype                #=> XSD.boolean
  #   RDF::Literal.new(123).datatype                 #=> XSD.integer
  #   RDF::Literal.new(9223372036854775807).datatype #=> XSD.integer
  #   RDF::Literal.new(3.1415).datatype              #=> XSD.double
  #   RDF::Literal.new(Time.now).datatype            #=> XSD.dateTime
  #   RDF::Literal.new(Date.new(2010)).datatype      #=> XSD.date
  #   RDF::Literal.new(DateTime.new(2010)).datatype  #=> XSD.dateTime
  #
  # @see http://www.w3.org/TR/rdf-concepts/#section-Literals
  # @see http://www.w3.org/TR/rdf-concepts/#section-Datatypes-intro
  class Literal
    autoload :Boolean,            'rdf/model/literal/boolean'
    autoload :Numeric,            'rdf/model/literal/numeric'
    autoload :Integer,            'rdf/model/literal/integer'
    autoload :NonPositiveInteger, 'rdf/model/literal/integer'
    autoload :NegativeInteger,    'rdf/model/literal/integer'
    autoload :Long,               'rdf/model/literal/integer'
    autoload :Int,                'rdf/model/literal/integer'
    autoload :Short,              'rdf/model/literal/integer'
    autoload :Byte,               'rdf/model/literal/integer'
    autoload :NonNegativeInteger, 'rdf/model/literal/integer'
    autoload :UnsignedLong,       'rdf/model/literal/integer'
    autoload :UnsignedInt,        'rdf/model/literal/integer'
    autoload :UnsignedShort,      'rdf/model/literal/integer'
    autoload :UnsignedInteger,    'rdf/model/literal/integer'
    autoload :UnsignedByte,       'rdf/model/literal/double'
    autoload :PositiveInteger,    'rdf/model/literal/double'
    autoload :Double,             'rdf/model/literal/double'
    autoload :Decimal,            'rdf/model/literal/decimal'
    autoload :Date,               'rdf/model/literal/date'
    autoload :DateTime,           'rdf/model/literal/datetime'
    autoload :Time,               'rdf/model/literal/time'
    autoload :Token,              'rdf/model/literal/token'
    autoload :XML,                'rdf/model/literal/xml'

    include RDF::Term

    ##
    # @private
    def self.new(value, options = {})
      klass = case
        when !self.equal?(RDF::Literal)
          self # subclasses can be directly constructed without type dispatch
        when datatype = options[:datatype]
          case RDF::URI(datatype)
            when XSD.boolean
              RDF::Literal::Boolean
            when XSD.integer
              RDF::Literal::Integer
            when XSD.long
              RDF::Literal::Long
            when XSD.int
              RDF::Literal::Int
            when XSD.short
              RDF::Literal::Short
            when XSD.byte
              RDF::Literal::Byte
            when XSD.float
              RDF::Literal::Float
            when XSD.double
              RDF::Literal::Double
            when XSD.decimal
              RDF::Literal::Decimal
            when XSD.date
              RDF::Literal::Date
            when XSD.dateTime
              RDF::Literal::DateTime
            when XSD.time
              RDF::Literal::Time
            when XSD.nonPositiveInteger
              RDF::Literal::NonPositiveInteger
            when XSD.negativeInteger
              RDF::Literal::NegativeInteger
            when XSD.nonNegativeInteger
              RDF::Literal::NonNegativeInteger
            when XSD.positiveInteger
              RDF::Literal::PositiveInteger
            when XSD.unsignedLong
              RDF::Literal::UnsignedLong
            when XSD.unsignedInt
              RDF::Literal::UnsignedInt
            when XSD.unsignedShort
              RDF::Literal::UnsignedShort
            when XSD.unsignedByte
              RDF::Literal::UnsignedByte
            when XSD.token, XSD.language
              RDF::Literal::Token
            when RDF.XMLLiteral
              RDF::Literal::XML
            else self
          end
        else case value
          when ::TrueClass  then RDF::Literal::Boolean
          when ::FalseClass then RDF::Literal::Boolean
          when ::Integer    then RDF::Literal::Integer
          when ::Float      then RDF::Literal::Double
          when ::BigDecimal then RDF::Literal::Decimal
          when ::DateTime   then RDF::Literal::DateTime
          when ::Date       then RDF::Literal::Date
          when ::Time       then RDF::Literal::Time # FIXME: Ruby's Time class can represent datetimes as well
          when ::Symbol     then RDF::Literal::Token
          else self
        end
      end
      literal = klass.allocate
      literal.send(:initialize, value, options)
      literal.validate!     if options[:validate]
      literal.canonicalize! if options[:canonicalize]
      literal
    end

    TRUE  = RDF::Literal.new(true).freeze
    FALSE = RDF::Literal.new(false).freeze
    ZERO  = RDF::Literal.new(0).freeze

    # @return [Symbol] The language tag (optional).
    attr_accessor :language

    # @return [URI] The XML Schema datatype URI (optional).
    attr_accessor :datatype

    ##
    # @param  [Object] value
    # @option options [Symbol] :language (nil)
    # @option options [URI]    :datatype (nil)
    def initialize(value, options = {})
      @object   = value
      @string   = options[:lexical] if options[:lexical]
      @language = options[:language].to_s.to_sym if options[:language]
      @datatype = RDF::URI(options[:datatype]) if options[:datatype]
    end

    ##
    # Returns the value as a string.
    #
    # @return [String]
    def value
      @string || to_s
    end

    ##
    # @return [Object]
    def object
      @object || case datatype
        when XSD.string, nil
          value
        when XSD.boolean
          %w(true 1).include?(value)
        when XSD.integer, XSD.long, XSD.int, XSD.short, XSD.byte
          value.to_i
        when XSD.double, XSD.float
          value.to_f
        when XSD.decimal
          ::BigDecimal.new(value)
        when XSD.date
          ::Date.parse(value)
        when XSD.dateTime
          ::DateTime.parse(value)
        when XSD.time
          ::Time.parse(value)
        when XSD.nonPositiveInteger, XSD.negativeInteger
          value.to_i
        when XSD.nonNegativeInteger, XSD.positiveInteger
          value.to_i
        when XSD.unsignedLong, XSD.unsignedInt, XSD.unsignedShort, XSD.unsignedByte
          value.to_i
      end
    end

    ##
    # Returns `true`.
    #
    # @return [Boolean] `true` or `false`
    def literal?
      true
    end

    ##
    # Returns `false`.
    #
    # @return [Boolean] `true` or `false`
    def anonymous?
      false
    end

    ##
    # Returns a hash code for this literal.
    #
    # @return [Fixnum]
    def hash
      to_s.hash
    end

    ##
    # Determins if `self` is the same term as `other`.
    #
    # @example
    #   RDF::Literal(1).eql?(RDF::Literal(1.0))  #=> false
    #
    # @param  [Object] other
    # @return [Boolean] `true` or `false`
    def eql?(other)
      self.equal?(other) ||
        (self.class.eql?(other.class) &&
         self.value.eql?(other.value) &&
         self.language.to_s.downcase.eql?(other.language.to_s.downcase) &&
         self.datatype.eql?(other.datatype))
    end

    ##
    # Returns `true` if this literal is equivalent to `other` (with type check).
    #
    # @example
    #   RDF::Literal(1) == RDF::Literal(1.0)     #=> true
    #
    # @param  [Object] other
    # @return [Boolean] `true` or `false`
    # @raise [TypeError] if Literal terms are not comparable
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal
    # @see http://www.w3.org/TR/rdf-concepts/#section-Literal-Equality
    def equal_tc?(other)
      case other
      when Literal
        case
        when self.eql?(other)
          #puts "eql?"
          true
        when self.has_language? && self.language.to_s.downcase == other.language.to_s.downcase
          self.value == other.value
        when (self.simple? || self.datatype == XSD.string) && (other.simple? || other.datatype == XSD.string)
          #puts "(self.simple? || self.datatype == XSD.string) && (other.simple? || other.datatype == XSD.string)"
          self.value == other.value
        when other.comperable_datatype?(self) || self.comperable_datatype?(other)
          # Comoparing plain with undefined datatypes does not generate an error, but returns false
          # From data-r2/expr-equal/eq-2-2.
          false
        else
          raise TypeError, "unable to determine whether #{self.inspect} and #{other.inspect} are equivalent"
        end
      when String
        self.plain? && self.value.eql?(other)
      else false
      end
    end
    
    ##
    # Returns `true` if this literal is equivalent to `other`.
    #
    # @example
    #   RDF::Literal(1) == RDF::Literal(1.0)     #=> true
    #
    # @param  [Object] other
    # @return [Boolean] `true` or `false`
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal
    # @see http://www.w3.org/TR/rdf-concepts/#section-Literal-Equality
    def ==(other)
      self.equal_tc?(other) rescue false
    end
    alias_method :===, :==

    ##
    # Returns `true` if this is a plain literal.
    #
    # @return [Boolean] `true` or `false`
    # @see http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal
    def plain?
      language.nil? && datatype.nil?
    end
    alias_method :simple?, :plain?

    ##
    # Returns `true` if this is a language-tagged literal.
    #
    # @return [Boolean] `true` or `false`
    # @see http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal
    def has_language?
      !language.nil?
    end
    alias_method :language?, :has_language?

    ##
    # Returns `true` if this is a datatyped literal.
    #
    # @return [Boolean] `true` or `false`
    # @see http://www.w3.org/TR/rdf-concepts/#dfn-typed-literal
    def has_datatype?
      !datatype.nil?
    end
    alias_method :datatype?,  :has_datatype?
    alias_method :typed?,     :has_datatype?
    alias_method :datatyped?, :has_datatype?

    ##
    # Returns `true` if the value adheres to the defined grammar of the
    # datatype.
    #
    # @return [Boolean] `true` or `false`
    # @since  0.2.1
    def valid?
      grammar = self.class.const_get(:GRAMMAR) rescue nil
      grammar.nil? || !!(value =~ grammar)
    end

    ##
    # Returns `true` if the value does not adhere to the defined grammar of
    # the datatype.
    #
    # @return [Boolean] `true` or `false`
    # @since  0.2.1
    def invalid?
      !valid?
    end

    ##
    # Returns `true` if the literal has a datatype and the comparison should
    # return false instead of raise a type error.
    #
    # This behavior is intuited from SPARQL data-r2/expr-equal/eq-2-2
    # @return [Boolean]
    def comperable_datatype?(other)
      return false unless self.plain?

      case other
      when RDF::Literal::Numeric, RDF::Literal::Boolean,
           RDF::Literal::Date, RDF::Literal::Time, RDF::Literal::DateTime
        false
      else
        # An unknown datatype can be used for comparison
        other.datatype && other.datatype != XSD.string
      end
    end

    ##
    # Validates the value using {#valid?}, raising an error if the value is
    # invalid.
    #
    # @return [RDF::Literal] `self`
    # @raise  [ArgumentError] if the value is invalid
    # @since  0.2.1
    def validate!
      raise ArgumentError, "#{to_s.inspect} is not a valid <#{datatype.to_s}> literal" if invalid?
      self
    end
    alias_method :validate, :validate!

    ##
    # Returns a copy of this literal converted into its canonical lexical
    # representation.
    #
    # Subclasses should override `#canonicalize!` as needed and appropriate,
    # not this method.
    #
    # @return [RDF::Literal]
    # @since  0.2.1
    def canonicalize
      self.dup.canonicalize!
    end

    ##
    # Converts this literal into its canonical lexical representation.
    #
    # Subclasses should override this as needed and appropriate.
    #
    # @return [RDF::Literal] `self`
    # @since  0.3.0
    def canonicalize!
      @language = @language.to_s.downcase.to_sym if @language
      self
    end

    ##
    # Returns the value as a string.
    #
    # @return [String]
    def to_s
      @object.to_s
    end

    ##
    # Returns a developer-friendly representation of `self`.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, RDF::NTriples.serialize(self))
    end
  end # Literal
end # RDF
