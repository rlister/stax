module Stax
  class Stack < Base
    COLORS = {
      IN_SYNC:  :green,
      MODIFIED: :red,
      DELETED:  :red,
      ADD:      :green,
      REMOVE:   :red,
    }

    no_commands do
      ## start a drift detection job and wait for it to complete
      def run_drift_detection
        debug("Running drift detection for #{stack_name}")
        id = Aws::Cfn.detect_drift(stack_name: stack_name)
        puts "waiting for #{id}"
        loop do
          sleep(1)
          break unless Aws::Cfn.drift_status(id).detection_status == 'DETECTION_IN_PROGRESS'
        end
      end

      ## show the latest drift status for each resource
      def show_drifts
        debug("Resource drift status for #{stack_name}")
        Aws::Cfn.drifts(stack_name: stack_name).tap do |drifts|
          print_table drifts.map { |d|
            [d.logical_resource_id, d.resource_type, color(d.stack_resource_drift_status, COLORS), d.timestamp]
          }
        end
      end

      ## show drift diffs for out of sync resources
      def show_drifts_details(drifts)
        drifts.select{ |d| d.stack_resource_drift_status == 'MODIFIED' }.each do |r|
          debug("Property differences for #{r.logical_resource_id}")
          r.property_differences.each do |p|
            puts(
              p.property_path + ' ' + color(p.difference_type, COLORS),
              '  ' + set_color('-' + p.expected_value, :red),
              '  ' + set_color('+' + p.actual_value, :green)
            )
          end
        end
      end
    end

    desc 'drifts', 'stack drifts'
    def drifts
      run_drift_detection
      drifts = show_drifts
      show_drifts_details(drifts)
    end

  end
end