require 'mongrel_process_monitor'
class MongrelHeartbeatPlugin   < Scout::Plugin
  def build_report
    results = MongrelProcessMonitor.process_status
    is_up = true
    results.each_pair do |key,value|
       unless value
         alert("Mongrel On Port #{key} Not Responding")
         remember(:down_at => Time.now)
         is_up = false
       end
    end

    report(:up => is_up)
    remember(:was_up => is_up)
    if is_up
      memory.delete(:down_at)
    end

  end
end