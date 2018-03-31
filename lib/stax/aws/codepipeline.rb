module Stax
  module Aws
    class Codepipeline < Sdk

      class << self

        def client
          @_client ||= ::Aws::CodePipeline::Client.new
        end

        def stages(name)
          client.get_pipeline(name: name).pipeline.stages
        end

        def executions(name, num = nil)
          opt = {pipeline_name: name, max_results: num}
          token = nil
          summaries = []
          loop do
            s = client.list_pipeline_executions(opt.merge(next_token: token))
            summaries += s.pipeline_execution_summaries
            break if (token = s.next_token).nil?
            break if summaries.count >= num
          end
          summaries.first(num)
        end

        def execution(name, id)
          client.get_pipeline_execution(pipeline_name: name, pipeline_execution_id: id).pipeline_execution
        end

      end

    end
  end
end