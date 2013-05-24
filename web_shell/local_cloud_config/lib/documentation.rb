#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


def gen_md_from_file(folder_path, files)
  doc = ""
  accepted_formats = [".md"]
  files.each { |file|
    next if !(accepted_formats.include? File.extname(file))
    file_title = file.clone
    file_title.gsub!('.md','')
    file_title.gsub!('_',' ')
    doc += "\n\n# #{file_title}\n"
    doc += File.read("#{folder_path}#{file}")
    doc += '<hr/><hr/>'
  }
  # replace version in doc
  doc.gsub!('XXXX_VERSION',"#{get_sdk_version}")
  doc
end

def sdk_doc_md
  $sdk_documentation ||= begin
    files = get_files('../../docs/to_user/')
    doc_beginner = []
    doc_code_ex = []
    doc_others = []
    files.each { |file|
      if file.include?('Beginner::')
        doc_beginner << file
        next
      end
      if file.include?('Code Example::')
        doc_code_ex << file
        next
      end
      doc_others << file
    }

    files = []
    # first 'Beginner::'
    files += doc_beginner.sort
    # else other
    files += doc_others.sort
    # end 'Code Example::'
    files += doc_code_ex.sort

    gen_md_from_file('../../docs/to_user/', files)
  end
end

def sdk_patch_note_md
  $sdk_patch_note ||= begin
    files = get_files('../../docs/patch_note/')
    # reverse sort
    files = files.sort.reverse
    gen_md_from_file('../../docs/patch_note/', files)
  end
end

def render_documentation(content)
  @html_render = ''
  @toc_render = ''
  return if content == nil

  doc_render = Redcarpet::Render::ColorHTML.new(:with_toc_data => true, :filter_html  => false, :hard_wrap => true)
  markdown = Redcarpet::Markdown.new(doc_render,
    no_intra_emphasis: false,
    tables: true,
    fenced_code_blocks: true,
    autolink: true,
    strikethrough: true,
    lax_html_blocks: true,
    space_after_headers: true,
    superscript: true)

  @html_render = markdown.render(content)
  @toc_render =  doc_render.render_menu
end


def last_version_path
  @last_version_launched_path ||= '.last_version'
end
# if the version has changed or first time, goto documentation or patch note page
def check_version_change_to_user
  action = 0
  if !(File.exist?(last_version_path))
    action = 1
  else
    current_v = File.read(last_version_path)
    if (current_v.length > 5 && get_sdk_version.length > 5)
      if current_v[0..5] != get_sdk_version[0..5]
        action = 2
      end
    end
  end
  File.open(last_version_path, 'w') { |file| file.write(get_sdk_version) }
  action
end
