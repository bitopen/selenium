# frozen_string_literal: true

# Licensed to the Software Freedom Conservancy (SFC) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The SFC licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module Selenium
  module WebDriver
    class DriverFinder
      class << self
        def result(options, klass)
          path = klass.driver_path
          path = path.call if path.is_a?(Proc)
          exe = klass::EXECUTABLE

          results = if path
                      WebDriver.logger.debug("Skipping Selenium Manager; user provided #{exe} location: #{path}")
                      {driver_path: path}
                    else
                      SeleniumManager.results(*to_args(options))
                    end
          validate_files(**results)
        rescue StandardError => e
          WebDriver.logger.error("Exception occurred: #{e.message}")
          WebDriver.logger.error("Backtrace:\n\t#{e.backtrace&.join("\n\t")}")
          raise Error::NoSuchDriverError, "Unable to obtain #{exe} using Selenium Manager"
        end

        def path(options, klass)
          WebDriver.logger.deprecate('`DriverFinder.path`', '`DriverFinder.result`', id: :driver_finder)
          result(options, klass)[:driver_path]
        end

        private

        def to_args(options)
          args = ['--browser', options.browser_name]
          if options.browser_version
            args << '--browser-version'
            args << options.browser_version
          end
          if options.respond_to?(:binary) && !options.binary.nil?
            args << '--browser-path'
            args << options.binary.gsub('\\', '\\\\\\')
          end
          if options.proxy
            args << '--proxy'
            args << (options.proxy.ssl || options.proxy.http)
          end
          args
        end

        def validate_files(**opts)
          opts.each_value { |value| Platform.assert_executable(value) }
          opts
        end
      end
    end
  end
end
