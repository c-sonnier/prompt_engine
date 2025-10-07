module PromptEngine
  module ParameterProcessingConcern
    extend ActiveSupport::Concern
    
    private
    
    def process_parameters_with_files
      processed_params = params[:parameters]&.to_unsafe_h || {}
      
      uploaded_files = []
      
      if params[:files].present?
        general_files = params[:files].is_a?(Array) ? params[:files] : [params[:files]]
        uploaded_files.concat(general_files.compact.reject { |f| 
          f.blank? || (f.respond_to?(:original_filename) && f.original_filename.blank?) 
        })
      end
      
      processed_params[:files] = uploaded_files if uploaded_files.any?
      processed_params
    end
  end
end
