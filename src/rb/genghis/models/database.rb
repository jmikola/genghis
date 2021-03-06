module Genghis
  module Models
    class Database
      def initialize(database)
        @database = database
      end

      def name
        @database.name
      end

      def drop!
        @database.connection.drop_database(@database.name)
      end

      def create_collection(coll_name)
        @database.create_collection coll_name
        Collection.new(@database[coll_name])
      end

      def collections
        # TODO: should I be rejecting all of these `system*` collections?
        @collections ||= @database.collections.map { |c| Collection.new(c) unless c.name.start_with? 'system' }.compact
      end

      def [](coll_name)
        raise Genghis::CollectionNotFound.new(self, coll_name) unless @database.collection_names.include? coll_name
        Collection.new(@database[coll_name])
      end

      def as_json(*)
        {
          :id          => @database.name,
          :name        => @database.name,
          :size        => info['sizeOnDisk'],
          :count       => collections.count,
          :collections => collections.map { |c| c.name }
        }
      end

      def to_json(*)
        as_json.to_json
      end

      private

      def info
        @info ||= begin
          name = @database.name
          @database.connection['admin'].command({:listDatabases => true})['databases'].detect do |db|
            db['name'] == name
          end
        end
      end
    end
  end
end
