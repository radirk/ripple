# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require 'riak'
module Riak
  class CacheStore < ActiveSupport::Cache::Store
    attr_accessor :client
    attr_accessor :bucket

    def initialize(options = {})
      bucket_name = options.delete(:bucket) || '_cache'
      @client = Riak::Client.new(options)
      @bucket = Riak::Bucket.new(@client, bucket_name)
    end

    def write(key, value, options={})
      super do
        object = bucket.get_or_new(key)
        object.content_type = 'application/yaml'
        object.data = value
        object.store
      end
    end

    def read(key, options={})
      super do
        begin
          bucket[key].data
        rescue Riak::FailedRequest => fr
          raise fr unless fr.code == 404
          nil
        end
      end
    end

    def exist?(key)
      super do
        bucket.exists?(key)
      end
    end

    def delete_matched(matcher, options={})
      super do
        bucket.keys do |keys|
          keys.grep(matcher).each do |k|
            bucket.delete(k)
          end
        end
      end
    end

    def delete(key, options={})
      super do
        bucket.delete(key)
      end
    end
  end
end

ActiveSupport::Cache::RiakStore = Riak::CacheStore unless defined?(ActiveSupport::Cache::RiakStore)
