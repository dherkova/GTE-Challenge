# Copyright 2012, Olav Stetter

# A collection of meta routines for the NEST simulator.


import nest
import random



DEFAULT_NEURON_PARAMETERS = {
  "C_m"       : 1.0,
  "tau_m"     : 20.0,
  "t_ref"     : 2.0,
  "E_L"       : -70.0,
  "V_th"      : -50.0,
  "V_reset"   : -70.0
}
DEFAULT_TSODYKS_SYNAPSE_PARAMETERS = {
  "delay"     : 1.5,
  "tau_rec"   : 500.0,
  "tau_fac"   : 0.0,
  "U"         : 0.3
}



def uniq(sequence): # Not order preserving!
  return list(set(sequence))

# The following code was directly translated from te-datainit.cpp in TE-Causality
def determine_burst_rate(xindex, xtimes, total_timeMS, size, tauMS=50, burst_treshold=0.4):
  assert(len(xindex)==len(xtimes))
  if len(xindex)<1:
    print "-> no spikes recorded!"
    return 0.
  # print "DEBUG: spike times ranging from "+str(xtimes[0])+" to "+str(xtimes[-1])
  print "-> "+str(len(xtimes))+" spikes from "+str(len(uniq(xindex)))+" of "+str(size)+" possible cells recorded."
  print "-> single cell spike rate: "+str(1000.*float(len(xtimes))/(float(total_timeMS)*float(size)))+" Hz"
  samples = int(xtimes[-1]/float(tauMS))
  # 1.) generate HowManyAreActive-signal (code directly translated from te-datainit.cpp)
  startindex = -1
  endindex = 0
  tinybit_spikenumber = -1
  HowManyAreActive = []
  for s in range(samples):
    ttExactMS = s*tauMS
    HowManyAreActiveNow = 0
    while (endindex+1<len(xtimes) and xtimes[endindex+1]<=ttExactMS+tauMS):
      endindex += 1
    HowManyAreActiveNow = len(uniq(xindex[max(0,startindex):endindex+1]))
    # print "DEBUG: startindex "+str(startindex)+", endindex "+str(endindex)+": HowManyAreActiveNow = "+str(HowManyAreActiveNow)
    
    if startindex <= endindex:
      startindex = 1 + endindex
    
    if float(HowManyAreActiveNow)/size > burst_treshold:
      HowManyAreActive.append(1)
    else:
      HowManyAreActive.append(0)
  
  # 2.) calculate inter-burst-intervals
  oldvalue = 0
  IBI = 0
  IBIsList = []
  for s in HowManyAreActive:
    switch = [oldvalue,s]
    if switch == [0,0]:
      IBI += 1
    elif switch == [0,1]:
      IBIsList.append(IBI)
      IBI = 0 # so we want to measure burst rate, not actually the IBIs
    oldvalue = s
  if IBI>0 and len(IBIsList)>0:
    IBIsList.append(IBI)
  print "-> "+str(len(IBIsList))+" bursts detected."
  # 3.) calculate burst rate in Hz
  if len(IBIsList)==0:
    return 0.
  else:
    return 1./(float(tauMS)/1000.*float(sum(IBIsList))/float(len(IBIsList)))


def go_create_network(yamlobj, weight, JENoise, noise_rate, print_output=False, fraction_of_connections=1.0, subnetwork_index_in_YAML=-1, block_inh=False, block_exc=False):
  weights_are_given_as_array_for_each_subnet = hasattr(weight, "insert")
  size = yamlobj.get('size')
  cons = yamlobj.get('cons')
  print "-> We have a network of "+str(size)+" nodes and "+str(cons)+" connections overall."
  if block_inh:
    print "-> Inhibitory synapses blocked."
  if block_exc:
    print "-> Excitatory synapses blocked."
  YAML_ID_offset = 0
  if subnetwork_index_in_YAML >= 0:
    # Collect list of cell indices that belong to the right subnetwork
    subnetwork_indices = []
    for i in range(len(yamlobj.get('nodes'))): # i starts counting at 0
      thisnode = yamlobj.get('nodes')[i]
      if thisnode.has_key('subset') and (thisnode.get('subset') == subnetwork_index_in_YAML):
        subnetwork_indices.append(i)
      # print "DEBUG: node with ID {id} has subset key {s}".format(id=thisnode.get('id'), s=thisnode.get('subset'))
    # Right now the logic later only works of the subnetworks is a continuous range of IDs,
    # so make sure that that is really the case.
    assert len(subnetwork_indices) > 0
    assert subnetwork_indices == range(min(subnetwork_indices), max(subnetwork_indices)+1)
    size = len(subnetwork_indices)
    YAML_ID_offset = min(subnetwork_indices)
    print "-> Limiting construction to subnetwork #"+str(subnetwork_index_in_YAML)+" ("+str(size)+" neurons, YAML ID offset "+str(YAML_ID_offset)+")."
  
  print "Resetting and creating network..."
  nest.ResetKernel()
  nest.SetKernelStatus({"resolution": 0.1, "print_time": False, "overwrite_files":True})
  nest.SetDefaults("iaf_neuron", DEFAULT_NEURON_PARAMETERS)
  neuronsE = nest.Create("iaf_neuron", size)
  # Save GID offset of first neuron - this has the advantage that the output later will be
  # independent of the point at which the neurons were created
  GIDoffset = neuronsE[0]
  espikes = nest.Create("spike_detector")
  noise = nest.Create("poisson_generator", 1, {"rate":noise_rate})
  nest.ConvergentConnect(neuronsE, espikes)
  # Warning: delay is overwritten later if weights are given in the YAML file!
  nest.SetDefaults("tsodyks_synapse", DEFAULT_TSODYKS_SYNAPSE_PARAMETERS)
  if weights_are_given_as_array_for_each_subnet:
    nest.CopyModel("tsodyks_synapse", "exc", {"weight": weight[0]}) # will anyway be reset later
  else:
    nest.CopyModel("tsodyks_synapse", "exc", {"weight": weight})
  nest.CopyModel("static_synapse","poisson",{"weight":JENoise})
  nest.DivergentConnect(noise,neuronsE,model="poisson")
  # print "Loading connections from YAML file..."
  added_connections = 0
  # Print additional information if present in YAML file
  if print_output:
    if yamlobj.has_key('notes'):
      print "-> notes of YAML file: "+yamlobj.get('notes')
    if yamlobj.has_key('createdAt'):
      print "-> created: "+yamlobj.get('createdAt')
  
  for i in range(len(yamlobj.get('nodes'))): # i starts counting at 0
    thisnode = yamlobj.get('nodes')[i]
    # Make sure neurons are ordered
    assert int(thisnode.get('id')) == i + 1
    # Quick fix: make sure we are reading the neurons in order and that none is skipped
    # print "DEBUG: iterator = "+str(i)+", cfrom = "+str(cfrom)
    if subnetwork_index_in_YAML < 0 or thisnode.get('subset') == subnetwork_index_in_YAML:
      # ID starts counting with 1, so substract one later to get to index starting with 0
      cfrom = int(thisnode.get('id')) - 1 - YAML_ID_offset
      # assert cfrom == neuronsE[cfrom] - GIDoffset
      # assert i == cfrom
      if thisnode.has_key('connectedTo'):
        cto_list = thisnode.get('connectedTo')
        for j in range(len(cto_list)):
          # again, substract 1 as for cfrom
          cto = int(cto_list[j]) - 1 - YAML_ID_offset
          if random.random() <= fraction_of_connections: # choose only subset of connections
            weight_here = 0.0
            # Set up case flags for later (just for readability)
            weights_are_given_in_YAML = thisnode.has_key('weights')
            subnet_index_is_given_in_YAML = thisnode.has_key('subset')
            # Initialize weight with value supplied as argument to fn. call
            if weights_are_given_as_array_for_each_subnet:
              assert subnet_index_is_given_in_YAML
              weight_here = weight[thisnode.get('subset')-1]
            else:
              weight_here = weight
            # Factor in weight given in the YAML file, if any
            if weights_are_given_in_YAML:
              assert len(thisnode.get('weights')) == len(cto_list)
              weight_here *= thisnode.get('weights')[j]
            # Create connection unless it's out of the subnet or the type of synapse is blocked
            if (cto >= 0) and (cto < size):
              if (weight_here > 0.0 and not(block_exc)) or (weight_here < 0.0 and not(block_inh)):
                nest.Connect([neuronsE[cfrom]], [neuronsE[cto]], weight_here, 1.5, model="exc")
                if print_output:
                  print "-> added connection: from #"+str(cfrom)+" to #"+str(cto)+" with weight "+str(weight_here)
                added_connections = added_connections+1
  
  print "-> "+str(added_connections)+" out of "+str(cons)+" connections (in YAML source) created."
  return [size, added_connections, neuronsE, espikes, noise, GIDoffset]
