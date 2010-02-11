module DrNicMagicModels

  # ONE Schema per namespace module
  # Person, Company, etc share the Object namespace module, ie. ::Person, ::Company
  # Blog::Post, Blog::Comment, share the Blog namespace module
  class Schema
    attr_reader :modul

    def initialize(modul)
      @modul = modul
      @table_name_prefix = modul.instance_variable_get("@table_name_prefix") rescue ''
      logger.info "Create Schema for #{@modul}, table_name_prefix '#{@table_name_prefix}'"
    end

    cattr_accessor :inflector
    cattr_accessor :superklass

    # Need to store models etc per-module, not in @ @models
    def inflector
      @inflector ||= Inflector.new
    end

    # all in lower case please
    ReservedTables = [:schema_info, :sessions]
    @models = nil

    def logger
      @logger ||= DrNicMagicModels::Logger
    end

    def models
      load_schema if @models.nil?
      @models
    end

    def tables
      load_schema if @tables.nil?
      @tables
    end

    def table_names
      load_schema if @table_names.nil?
      @table_names
    end

    def fks_on_table(table_name)
      load_schema if @models.nil?
      @fks_by_table[table_name.to_s] || []
    end

    # active record only support 2 column link tables, otherwise use a model table, has_many and through
    def is_link_table?(table_name)
      load_schema if @models.nil?
      return @link_tables[table_name] if ! @link_tables[table_name].nil?
      column_names = @conn.columns(table_name).map{|x| x.name }
      @link_tables[table_name] = ! column_names.include?("id") && column_names.length == 2 && column_names.select { |x| x =~ /_id$/ } == column_names
      return @link_tables[table_name]
    end

    def link_tables_for_class(klass)
      load_schema if @models.nil?
    end

    def load_schema(preload = false)
      return if !@models.nil?

      @superklass ||= ActiveRecord::Base
      raise "No database connection" if !(@conn = @superklass.connection)

      @models = ModelHash.new
      @tables = Hash.new
      @fks_by_table = Hash.new
      @link_tables = Hash.new

      @table_names = @conn.tables
      @table_names = @table_names.grep(/^#{@table_name_prefix}/) if @table_name_prefix
      @table_names = @table_names.sort

      logger.info "For #{modul} tables are #{@table_names.inspect}"

      # Work out which tables are in the model and which aren't
      @table_names.each do |table_name|

        # deal with reserved tables & link_tables && other stray id-less tables
        #key = 'id'
        #case ActiveRecord::Base.primary_key_prefix_type
        #  when :table_name
        #    key = Inflector.foreign_key(table_name, false)
        #  when :table_name_with_underscore
        #    key = Inflector.foreign_key(table_name)
        #end
        #next if ReservedTables.include?(table_name.downcase.to_sym) ||
        #        is_link_table?(table_name) ||
        #        ! @conn.columns(table_name).map{ |x| x.name}.include?(key)

        table_name_clean = table_name.gsub(/^#{@table_name_prefix}/,'')

        # a model table then...
        model_class_name = inflector.class_name(table_name_clean)

        logger.debug "Got a model table: #{table_name} => class #{model_class_name}"

        @models[model_class_name] = table_name
        @tables[table_name] = model_class_name

        if preload
          # create by MAGIC!
          klass = model_class_name.constantize

          # Process FKs?
          if @conn.supports_fetch_foreign_keys?

            table_names.each do |table_name|
              logger.debug "Getting FKs for #{table_name}"
              @fks_by_table[table_name] = Array.new
              @conn.foreign_key_constraints(table_name).each do |fk|
                logger.debug "Got one: #{fk}"
                @fks_by_table[table_name].push(fk)
              end # do each fk

            end # each table
          end

          # Try to work out our link tables now...
          @models.keys.sort.each{|klass| process_table(@models[klass.to_s])}
          @link_tables.keys.sort.each{|table_name| process_link_table(table_name) if @link_tables[table_name]}
        end
      end

    end

    def process_table(table_name)

      logger.debug "Processing model table #{table_name}"

      # ok, so let's look at the foreign keys on the table...
      belongs_to_klass = @tables[table_name].constantize rescue return

      processed_columns = Hash.new

      fks_on_table(table_name).each do |fk|
        logger.debug "Found FK column by suffix _id [#{fk.foreign_key}]"
        has_some_klass = Inflector.classify(fk.reference_table).constantize rescue next
      processed_columns[fk.foreign_key] = { :has_some_klass => has_some_klass }
        processed_columns[fk.foreign_key].merge! add_has_some_belongs_to(belongs_to_klass, fk.foreign_key, has_some_klass) rescue next
      end

      column_names = @conn.columns(table_name).map{ |x| x.name}
      column_names.each do |column_name|
        next if not column_name =~ /_id$/
        logger.debug "Found FK column by suffix _id [#{column_name}]"
        if processed_columns.key?(column_name)
          logger.debug "Skipping, already processed"
          next
        end
        has_some_klass = Inflector.classify(column_name.sub(/_id$/,"")).constantize rescue next
      processed_columns[column_name] = { :has_some_klass => has_some_klass }
        processed_columns[column_name].merge! add_has_some_belongs_to(belongs_to_klass, column_name, has_some_klass) rescue next
      end

      #TODO: what if same classes in table?

      # is this a link table with attributes? (has_many through?)
      return if processed_columns.keys.length < 2

      processed_columns.keys.each do |key1|
        processed_columns.keys.each do |key2|
          next if key1 == key2
          logger.debug "\n*** #{processed_columns[key1][:has_some_class]}.send 'has_many', #{processed_columns[key2][:belongs_to_name].to_s.pluralize.to_sym}, :through => #{processed_columns[key2][:has_some_name]}\n\n"
          processed_columns[key1][:has_some_class].send 'has_many', processed_columns[key2][:belongs_to_name].to_s.pluralize.to_sym, :through => processed_columns[key2][:has_some_name].to_sym
        end
      end

    end

    def add_has_some_belongs_to(belongs_to_klass, belongs_to_fk, has_some_klass)

      logger.debug "Trying to add a #{belongs_to_klass} belongs_to #{has_some_klass}..."

      # so this is a belongs_to & has_some style relationship...
      # is it a has_many, or a has_one? Well, let's assume a has_one has a unique index on the column please... good db design, haha!
      unique = belongs_to_klass.get_unique_index_columns.include?(belongs_to_fk)
      belongs_to_name = belongs_to_fk.sub(/_id$/, '').to_sym

      logger.debug "\n*** #{belongs_to_klass}.send 'belongs_to', #{belongs_to_name}, :class_name => #{has_some_klass}, :foreign_key => #{belongs_to_fk}\n"
      belongs_to_klass.send(:belongs_to, belongs_to_name, :class_name => has_some_klass.to_s, :foreign_key => belongs_to_fk.to_sym)

      # work out if we need a prefix
      has_some_name = (
       (unique ? belongs_to_klass.table_name.singularize : belongs_to_klass.table_name) +
       (belongs_to_name.to_s == has_some_klass.table_name.singularize ? "" : "_as_"+belongs_to_name.to_s)
      ).downcase.to_sym
      method = unique ? :has_one : :has_many
      logger.debug "\n*** #{has_some_klass}.send(#{method}, #{has_some_name}, :class_name => #{belongs_to_klass.to_s}, :foreign_key => #{belongs_to_fk.to_sym})\n\n"
      has_some_klass.send(method, has_some_name, :class_name => belongs_to_klass.to_s, :foreign_key => belongs_to_fk.to_sym)

      return { :method => method, :belongs_to_name => belongs_to_name, :has_some_name => has_some_name, :has_some_class => has_some_klass  }

    end

    def process_link_table(table_name)

      logger.debug "Processing link table #{table_name}"

      classes_map = Hash.new
      column_names = @conn.columns(table_name).map{ |x| x.name}

      # use foreign keys first
      fks_on_table(table_name).each do |fk|
        logger.debug "Processing fk: #{fk}"
        klass = Inflector.classify(fk.reference_table).constantize rescue logger.debug("Cannot find model #{class_name} for table #{fk.reference_table}") && return
        classes_map[fk.foreign_key] = klass
      end

      logger.debug "Got #{classes_map.keys.length} references from FKs"

      if classes_map.keys.length < 2

        #Fall back on good ol _id recognition

        column_names.each do |column_name|

          # check we haven't processed by fks already
          next if ! classes_map[column_name].nil?
          referenced_table = column_name.sub(/_id$/, '')

          begin
            klass = Inflector.classify(referenced_table).constantize
            # fall back on FKs here
            if ! klass.nil?
              classes_map[column_name] = klass
            end
          rescue
          end
        end
      end

      # not detected the link table?
      logger.debug "Got #{classes_map.keys.length} references"
      logger.debug "Cannot detect both tables referenced in link table" && return if classes_map.keys.length != 2

      logger.debug "Adding habtm relationship"

      logger.debug "\n*** #{classes_map[column_names[0]]}.send 'has_and_belongs_to_many', #{column_names[1].sub(/_id$/,'').pluralize.to_sym}, :class_name => #{classes_map[column_names[1]].to_s}, :join_table => #{table_name.to_sym}\n"
      logger.debug "\n*** #{classes_map[column_names[1]]}.send 'has_and_belongs_to_many', #{column_names[0].sub(/_id$/,'').pluralize.to_sym}, :class_name => #{classes_map[column_names[0]].to_s}, :join_table => #{table_name.to_sym}\n\n"

      classes_map[column_names[0]].send 'has_and_belongs_to_many', column_names[1].sub(/_id$/,'').pluralize.to_sym, :class_name => classes_map[column_names[1]].to_s, :join_table => table_name.to_sym
      classes_map[column_names[1]].send 'has_and_belongs_to_many', column_names[0].sub(/_id$/,'').pluralize.to_sym, :class_name => classes_map[column_names[0]].to_s, :join_table => table_name.to_sym

    end
  end

  class ModelHash < Hash
    def unenquire(class_id)
      @enquired ||= {}
      @enquired[class_id = class_id.to_s] = false
    end

    def enquired?(class_id)
      @enquired ||= {}
      @enquired[class_id.to_s]
    end

    def [](class_id)
      enquired?(class_id = class_id.to_s)
      @enquired[class_id] = true
      super(class_id)
    end
  end
end
