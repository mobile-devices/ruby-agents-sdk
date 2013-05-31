#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module PUNK

  class PunkEvent < Struct.new(:type, :way, :title, :start_time, :end_time, :elaspe_time, :content)
  end

  class PunkPendingStack < Struct.new(:id, :lines)
  end

  def un_punk(txt_src)
    punk_events = []

    punks_pending = []

    txt_src.each_line{ |line|
      tak = line.index('PUNKabeNK_')
      if tak != nil
        puts "trig #{line}"
        p ''
        # get id
        id = line.split('PUNKabeNK_')[1]
        id.delete!("\n")

        puts "NEW ID '#{id}'"
        p ''

        # create new pending stack
        punks_pending << PunkPendingStack.new(id, [])
        next
      end
      tak = line.index('PUNKabe_')
      if tak != nil
        puts "trig #{line}"
        p ''
        # get id
        params = line.split('PUNKabe_')[1]
        id = params.split('_axd_').first
        rjson = params.split('_axd_')[1]

        puts "END ID '#{id}' with raw json = #{rjson}"
        p ''

        json = JSON.parse(rjson)
        puts "json = #{json}"
        p ''

        # search if stack contain
        punks_pending.each { |pending|
          if pending['id'] == id
            puts "found #{id} in pending with #{pending.lines.size} lines !"

            content = ''
            pending.lines.each { |line|
              content += "#{line}<br>"
            }

            puts "content:\n#{content}"
            p ''


            punk_events << PunkEvent.new(json['type'], json['way'], json['title'], line[15..22], '', '', content)
            punks_pending.delete_at(punks_pending.index(pending))
            break
          end
        }
        next
      end

      # fill all pending with current line
      punks_pending.each { |pending|
        pending.lines << line.delete!("\n")
      }
    }

    #puts "Reconstruct successful with :"
    #p punk_events

    punk_events
  end


  def title_to_html(title)
    title.gsub!('->','<i class="icon-arrow-right icon-white"></i>')
    title.gsub!('<-','<i class="icon-arrow-left icon-white"></i>')

    title.gsub!('SERVER','<i class="icon-th icon-white"></i>')

    title.gsub!('PRESENCE','<i class="icon-star icon-white"></i>')
    title.gsub!('MSG','<i class="icon-envelope icon-white"></i>')
    title.gsub!('TRACK','<i class="icon-th-list icon-white"></i>')
    title.gsub!('ORDER','<i class="icon-fire icon-white"></i>')

    title.gsub!('ACK','<i class="icon-share icon-white"></i>')

    agent_pos = title.index('AGENT')
    agent_end_pos = title.index('TNEGA')
    if agent_pos != nil && agent_end_pos != nil
      agent_name = title[(agent_pos+6)..(agent_end_pos-1)]




      title.gsub!(title[agent_pos..(agent_end_pos+4)], "<span class=\"label label-warning\">#{agent_name}</span>")

      #title.gsub!(title[agent_pos..(agent_end_pos+4)], "[<i class=\"icon-th-large icon-white\"></i> #{agent_name}]")

    end

    title
  end


  def gen_server_crash_title()
    `cd ../local_cloud; ./local_cloud.sh is_running`
    used_server_run_id =  File.read('/tmp/mdi_server_run_id')
    server_running =  File.read('/tmp/local_cloud_running')

    p "server_run_id = '#{$server_run_id}'' and used_server_run_id = '#{used_server_run_id}'"

    if "#{$server_run_id}" == "#{used_server_run_id}" && server_running == 'no'
      p "SERVER is broken"
      title_to_html("SERVER master crash fail")
    else
      p "SERVER is alive"
      ''
    end
  end

end
