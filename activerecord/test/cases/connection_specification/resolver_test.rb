require "cases/helper"

module ActiveRecord
  module ConnectionAdapters
    class ConnectionSpecification
      class ResolverTest < ActiveRecord::TestCase
        def resolve(spec, config={})
          Resolver.new(config).resolve(spec)
        end

        def spec(spec, config={})
          Resolver.new(config).spec(spec)
        end

        def test_url_invalid_adapter
          error = assert_raises(LoadError) do
            spec 'ridiculous://foo?encoding=utf8'
          end

          assert_match "Could not load 'active_record/connection_adapters/ridiculous_adapter'", error.message
        end

        # The abstract adapter is used simply to bypass the bit of code that
        # checks that the adapter file can be required in.

        def test_url_from_environment
          spec = resolve :production, 'production' => 'abstract://foo?encoding=utf8'
          assert_equal({
            "adapter"  =>  "abstract",
            "host"     =>  "foo",
            "encoding" => "utf8" }, spec)
        end

        def test_url_sub_key
          spec = resolve :production, 'production' => {"url" => 'abstract://foo?encoding=utf8'}
          assert_equal({
            "adapter"  => "abstract",
            "host"     => "foo",
            "encoding" => "utf8" }, spec)
        end

        def test_url_sub_key_merges_correctly
          hash = {"url" => 'abstract://foo?encoding=utf8&', "adapter" => "sqlite3", "host" => "bar", "pool" => "3"}
          spec = resolve :production, 'production' => hash
          assert_equal({
            "adapter"  => "abstract",
            "host"     => "foo",
            "encoding" => "utf8",
            "pool"     => "3" }, spec)
        end

        def test_url_host_no_db
          spec = resolve 'abstract://foo?encoding=utf8'
          assert_equal({
            "adapter"  => "abstract",
            "host"     => "foo",
            "encoding" => "utf8" }, spec)
        end

        def test_url_host_db
          spec = resolve 'abstract://foo/bar?encoding=utf8'
          assert_equal({
            "adapter"  => "abstract",
            "database" => "bar",
            "host"     => "foo",
            "encoding" => "utf8" }, spec)
        end

        def test_url_port
          spec = resolve 'abstract://foo:123?encoding=utf8'
          assert_equal({
            "adapter"  => "abstract",
            "port"     => 123,
            "host"     => "foo",
            "encoding" => "utf8" }, spec)
        end

        def test_encoded_password
          password = 'am@z1ng_p@ssw0rd#!'
          encoded_password = URI.encode_www_form_component(password)
          spec = resolve "abstract://foo:#{encoded_password}@localhost/bar"
          assert_equal password, spec["password"]
        end

        def test_url_host_db_for_sqlite3
          spec = resolve 'sqlite3://foo:bar@dburl:9000/foo_test'
          assert_equal('/foo_test', spec["database"])
        end

        def test_url_host_memory_db_for_sqlite3
          spec = resolve 'sqlite3://foo:bar@dburl:9000/:memory:'
          assert_equal(':memory:', spec["database"])
        end
      end
    end
  end
end
