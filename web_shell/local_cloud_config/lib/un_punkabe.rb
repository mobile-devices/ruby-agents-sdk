#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module PUNK

  #============================== CLASSES ========================================

  class PunkEvent < Struct.new(:type, :way, :title, :start_time, :end_time, :elaspe_time, :msg_belong_to, :content)
  end

  class PunkPendingStack < Struct.new(:id, :lines, :action)
  end



  #============================== METHODS ========================================


  def self.un_punk(txt_src)
    punk_events = []

    punks_pending = []

    txt_src.each_line{ |line|
      tak = line.index('PUNKabeNK_') # start
      if tak != nil
        puts "trig #{line}"
        p ''
        # get id
        id = line.split('_')[1]
        id.delete!("\n")
        action = line.split('_')[2]
        action.delete!("\n")

        puts "NEW ID '#{id}' with action '#{action}'"
        p ''

        # create new pending stack
        punks_pending << PunkPendingStack.new(id, [], action)
        next
      end
      tak = line.index('PUNKabeDROP_') # break
      if tak != nil
        id = line.split('_')[1]
        id.delete!("\n")

        puts "drop #{id}"
        # rebuild stack
        tmp_pending = []
        punks_pending.each { |pending|
          if pending['id'] == id
            puts "dropping! #{id} #{punks_pending.size} pending left"
          else
            tmp_pending << pending
          end
        }
        punks_pending = tmp_pending
        next
      end

      tak = line.index('PUNKabe_') # end
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
        linked = false
        stk = 0
        tmp_pending = []
        punks_pending.each { |pending|
          puts "Search stack #{stk} in id=#{pending['id']}"
          if pending['id'] == id
            if !linked

              #find belong type (server agent X)
              title = json['title']
              agent_title = extract_agent_name(title)
              if agent_title != nil
                belong_to = agent_title
              else
                belong_to = 'SERVER'
              end


              punk_events << PunkEvent.new(json['type'], json['way'], title, line[15..22], '', '', belong_to, pending.lines)
              linked = true
              puts "found '#{id}' #{json['title']} (belong to #{belong_to}) in pending with #{pending.lines.size} lines !  #{punks_pending.size} pending left"
            else
              puts "delete '#{id}' #{punks_pending.size} pending left"
            end
          else
            tmp_pending << pending
          end
          stk+=1
        }
        punks_pending = tmp_pending
        next
      end

      # fill all pending with current line
      punks_pending.each { |pending|
        begin
        line.delete!("\n")
        rescue Exception => e
          # utf8 errors
          puts "error on line.delete #{e.inspect}"
        end

        if line != ''
          pending.lines << line
        end
      }
    }

    puts "We have #{punks_pending.size} pending with:"
    punks_pending.each { |pending|
      puts " > #{pending.id} (#{pending.action})"
    }

    # seek in an action is in progress
    pend = punks_pending.first

    pend = nil if !(is_server_alive)

    if pend == nil
      $pending_action = nil
    else
      $pending_action = pend.action
      puts "pending_action loading with #{pend.inspect} (#{punks_pending.size} pending)"
    end


    #puts "Reconstruct successful with :"
    #p punk_events

    punk_events
  end


  def self.title_to_html(title)
    title.gsub!('->','<i class="icon-arrow-right icon-white"></i>')
    title.gsub!('<-','<i class="icon-arrow-left icon-white"></i>')

    title.gsub!('SERVER','<i class="icon-th icon-white"></i>')

    title.gsub!('PRESENCE','<i class="icon-star icon-white"></i>')
    title.gsub!('MSG','<i class="icon-envelope icon-white"></i>')
    title.gsub!('TRACK','<i class="icon-road icon-white"></i>')
    title.gsub!('ORDER','<i class="icon-fire icon-white"></i>')
    title.gsub!('COLLECTION','<i class="icon-list icon-white"></i>')
    title.gsub!('ACK','<i class="icon-share icon-white"></i>')
    title.gsub!('POKE','<i class="icon-bell icon-white"></i>')
    title.gsub!('ASSET_CONFIG','<i class="icon-cog icon-white"></i>')

    agent_name = extract_agent_name(title)
    if agent_name != nil
      agent_pos = title.index('AGENT')
      agent_end_pos = title.index('TNEGA')
      title.gsub!(title[agent_pos..(agent_end_pos+4)], "<span class=\"label label-warning\">#{agent_name}</span>")
    end

    title
  end


  def self.is_server_alive
    `cd ../local_cloud; ./local_cloud.sh is_running`
    if File.exist?('/tmp/mdi_server_run_id')
      used_server_run_id =  File.read('/tmp/mdi_server_run_id')
    else
      used_server_run_id = nil
    end
    if File.exist?('/tmp/local_cloud_running')
      server_running =  File.read('/tmp/local_cloud_running')
    else
      server_running = nil
    end

    p "server_run_id = '#{$server_run_id}'' and used_server_run_id = '#{used_server_run_id}' and server_running=#{server_running}"

    if "#{$server_run_id}" == "#{used_server_run_id}" && server_running == 'no'
      p "SERVER is broken"
      return false
    else
      p "SERVER is alive"
      return true
    end
  end


  def self.gen_server_crash_title

    if PUNK.is_server_alive
      ''
    else
      title_to_html("SERVER master crash fail")
    end

  end

  def self.is_ruby_server_running()
    `cd ../local_cloud; ./local_cloud.sh is_running`
    false
    if File.exist?('/tmp/local_cloud_running')
      server_running =  File.read('/tmp/local_cloud_running')
      true if server_running == 'yes'
    end
  end

  def self.gen_loading_action()
    $pending_action
  end

  def self.extract_agent_name(txt)
    agent_pos = txt.index('AGENT')
    agent_end_pos = txt.index('TNEGA')
    if agent_pos != nil && agent_end_pos != nil
      txt[(agent_pos+6)..(agent_end_pos-1)]
    else
      nil
    end
  end


end
