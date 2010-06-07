module Hydra #:nodoc:
  module Messages #:nodoc:
    module Worker #:nodoc:
      # Message indicating that a worker needs a file to delegate to a runner
      class RequestFile < Hydra::Message
        def handle(master, worker) #:nodoc:
          master.send_file(worker)
        end
      end

      # Message telling the runner to create database.
      class CreateDatabase < Hydra::Message
        def handle(runner) #:nodoc:
          puts "CreateDatabase received in #{Process.pid}"
          ENV['TEST_ENV_NUMBER'] = "hydra_#{Process.pid}"

          schema_file = Rails.root.join('db','development_structure.sql')
          `/usr/local/mysql/bin/mysql -u root -f -e 'drop database if exists #{ENV['TEST_ENV_NUMBER']}'`
          `/usr/local/mysql/bin/mysqladmin -u root create #{ENV['TEST_ENV_NUMBER']}`
          `/usr/local/mysql/bin/mysql -u root #{ENV['TEST_ENV_NUMBER']} < #{schema_file}`
        end
      end

      # Message telling the Runner to run a file
      class RunFile < Hydra::Message
        # The file that should be run
        attr_accessor :file
        def serialize #:nodoc:
          super(:file => @file)
        end
        def handle(runner) #:nodoc:
          runner.run_file(@file)
        end
      end

      # Message to tell the Runner to shut down
      class Shutdown < Hydra::Message
        def handle(runner) #:nodoc:
          runner.stop
        end
      end

      # Message relaying the results of a worker up to the master
      class Results < Hydra::Messages::Runner::Results
        def handle(master, worker) #:nodoc:
          master.process_results(worker, self)
        end
      end

      # Message a worker sends to a master to verify the connection
      class Ping < Hydra::Message
        def handle(master, worker) #:nodoc:
          # We don't do anything to handle a ping. It's just to test
          # the connectivity of the IO
        end
      end
    end
  end
end
