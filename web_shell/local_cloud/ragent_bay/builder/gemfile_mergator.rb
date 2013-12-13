#tool to merge gem file in the sdk way

# return merge Gemfile content
# gemfiles_contents : arrawy of content
def merge_gem_file(master_gem_file, gemfiles_contents)
  master = []

  master << "# GENERATED GEMFILE. DON'T EDIT THIS FILE, YOUR CHANGES WILL BE LOST\n\n"

  master_gem_file.each_line do |line|
    master << line
  end

  gemfiles_contents.each do |content|
    content << "\n"
    content.each_line do |line|
      gem_name = get_gem_name(line)

      if gem_name != nil && !(is_gem_exist(master, gem_name))
        master << line
      end
    end
  end
  master.join("")
end


def is_gem_exist(array, name)
  array.each do |line|
    if line.include? "#{name}"
      return true
    end
  end
  return false
end


def get_gem_name(txt)
  #p "is_gem_line? of #{txt}"

  return nil unless txt[0,4] == 'gem '

  sp = txt.split('\'')
  p sp

  return nil unless sp.size > 2

  #p "gives #{sp[1]}"
  sp[1]
end