module Pantry

  # Use EDITOR to edit the contents of a remote file locally
  # The editor can validate the updated content to be YAML (more to be added as needed)
  # and will show errors and re-edit the file if validation fails.
  #
  # If the user chooses to cancel editing, #edit will return the original
  # content given to it.
  #
  # Usage is simple:
  #
  #   editor = FileEditor.new
  #   updated_content = editor.edit(file_contents, file_type)
  #
  class FileEditor

    def initialize
      @editor = ENV['EDITOR']
      raise "Please set EDITOR environment variable to a text editor." unless @editor
    end

    def edit(original_content, file_type)
      file = create_temp_file(original_content, file_type)
      new_content = ""

      loop do
        new_content = edit_file(file)

        is_valid, message = validate_content(new_content, file_type)
        break if is_valid

        Pantry.ui.say(message)
        if !Pantry.ui.continue?("Continue editing?")
          new_content = original_content
          break
        end
      end

      file.unlink
      new_content
    end

    protected

    def create_temp_file(file_contents, file_type)
      tempfile = Tempfile.new(["edit-in-line", ".#{file_type}"])
      tempfile.write(file_contents)
      tempfile.close
      tempfile
    end

    def edit_file(tempfile)
      system("#{@editor} #{tempfile.path}")
      File.read(tempfile.path)
    end

    def validate_content(content, file_type)
      begin
        Psych.parse(content, "config.yml")
        return true, nil
      rescue => ex
        return false, ex.message
      end
    end
  end

end
