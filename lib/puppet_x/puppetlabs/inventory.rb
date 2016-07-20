module PuppetX
  module Puppetlabs
    class Inventory
      REQUIRED_TYPES = [:group, :package, :service, :user].freeze

      attr_accessor :catalog

      def initialize
        Puppet::Type.loadall
        Puppet.initialize_facts

        @catalog = Puppet::Resource::Catalog.new
        Puppet::Type.eachtype do |type_class|
          type_class.instances.each do |i|
            catalog.add_resource(i)
          end if REQUIRED_TYPES.include?(type_class.name)
        end
      end

      def generate
        data = @catalog.relationship_graph.vertices.map(&:to_resource)
        format_resources(data).flatten
      end

      private
        def format_resources(array) # rubocop:disable Metrics/AbcSize
          array.collect do |hash|
            case hash.type
            when 'Package'
              {
                title: hash.title.to_s,
                resource: hash.type.downcase,
                provider: hash[:provider],
                versions: Array(hash[:ensure]).map(&:to_s)
              }
            when 'User'
              {
                title: hash.title.to_s,
                resource: hash.type.downcase,
                uid: hash[:uid],
                gid: hash[:gid],
                groups: hash[:groups],
                home: hash[:home],
                shell: hash[:shell],
                comment: hash[:comment]
              }
            when 'Group'
              {
                title: hash.title.to_s,
                resource: hash.type.downcase,
                gid: hash[:gid]
              }
            when 'Service'
              {
                title: hash.title.to_s,
                resource: hash.type.downcase,
                ensure: hash[:ensure],
                enable: hash[:enable],
                provider: hash[:provider]
              }
            end
          end
        end
    end
  end
end