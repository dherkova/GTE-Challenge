NETWORK_SIZES = [50, 100, 500]
TOPOL_INDICES = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6]
NETWORK_INDICES = [1]

DRY_RUN = false

puts "--- batch-launching spike simulator (dry run: #{DRY_RUN}) ---"

NETWORK_SIZES.each do |nn|
  TOPOL_INDICES.each do |cc|
    NETWORK_INDICES.each do |ii|
      id = "iNet#{ii}_Size#{nn}_CC#{cc.to_s.gsub('.','')}"
      topology_name = "topologies/topology_#{id}.yaml"
      indices_name = "spikes/indices_#{id}.dat"
      times_name = "spikes/times_#{id}.dat"
      status_name = "spikes/status_#{id}.txt"
      command = "nohup nice python ./CHA-adaptive-bursts.py #{topology_name} #{times_name} #{indices_name} > #{status_name} &"
      if DRY_RUN
        puts command
      else
        system(command)
      end
    end
  end
end

puts 'done.'
