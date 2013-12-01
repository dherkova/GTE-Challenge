#! /usr/bin/env python

# Copyright 2012, Olav Stetter

# NEST simulator designed to iterate over a number of input topologies
# (YAML) and to adjst the internal synaptic weight to always achieve an
# equal bursting rate across networks.

import sys
import nest
import numpy
import time
import yaml
import NEST_meta_routines as nest_meta




print "------ adaptive-multibursts, Olav Stetter, Fri 14 Oct 2011 ------"
# first, make sure command line parameters are fine
cmd_arguments = sys.argv
if len(cmd_arguments) != 4:
  print "usage: ./CHA-adaptive-bursts.py input_yaml_file spike_times_output_file spike_indices_output_file"
  sys.exit(0)
# else:
YAMLinputfilename = str(cmd_arguments[1])
spiketimefilename = str(cmd_arguments[2])
spikeindexfilename = str(cmd_arguments[3])


# ------------------------------ Simulation parameters ------------------------------ #
MAX_ADAPTATION_ITERATIONS = 100 # maximum number of iterations to find parameters for target bursting rate
ADAPTATION_SIMULATION_TIME = 200*1000. # in ms
hours = 1.
SIMULATION_TIME = hours*60.*60.*1000. # in ms
TARGET_BURST_RATE = 0.1 # in Hz
TARGET_BURST_RATE_ACCURACY_GOAL = 0.01 # in Hz
INITIAL_WEIGHT_JE = 8. # internal synaptic weight, initial value, in pA
WEIGHT_NOISE = 2*0.28*20.0 #4. # external synaptic weight, in pA
NOISE_RATE = 0.2 # rate of external inputs, in Hz
FRACTION_OF_CONNECTIONS = 1.0



# ------------------------------ Main loop starts here ------------------------------ #
startbuild = time.time()

print "Loading topology from disk..."
filestream = file(YAMLinputfilename,"r")
yamlobj = yaml.load(filestream)
filestream.close()
assert filestream.closed

# --- adaptation phase ---
print "Starting adaptation phase..."
weight = INITIAL_WEIGHT_JE
burst_rate = 0.0
adaptation_iteration = 1
last_burst_rates = []
last_JEs = []
upper_bound_on_weight = 1000.0
lower_bound_on_weight = 0.0
upper_bound_on_burst_rate = 1000.0
lower_bound_on_burst_rate = 0.0

while abs(burst_rate-TARGET_BURST_RATE)>TARGET_BURST_RATE_ACCURACY_GOAL:
  old_weight = weight
  if len(last_burst_rates)<2 or last_burst_rates[-1] == last_burst_rates[-2]:
    if len(last_burst_rates)>0:
      print "\n----------------------------- auto-burst stage II.) changing weight by 10% -----------------------------"
      if burst_rate > TARGET_BURST_RATE:
        weight *= 0.9
      else:
        weight *= 1.1
    else:
      print "\n----------------------------- auto-burst stage I.) initial run -----------------------------"
  else:
    print "\n----------------------------- auto-burst stage III.) linear extrapolation -----------------------------"
    # this assumes a monotonic relation between synaptic weight and burst rate
    weight = ((TARGET_BURST_RATE-last_burst_rates[-2])*(last_JEs[-1]-last_JEs[-2]) / (last_burst_rates[-1]-last_burst_rates[-2])) + last_JEs[-2]

  # apply previously found bounds to avoid oscillations
  if weight > upper_bound_on_weight or weight < lower_bound_on_weight:
    print "-> extrapolated weight {w} out of best found bounds, resetting...".format(w=weight)
    weight = 0.5*(lower_bound_on_weight + upper_bound_on_weight)
  assert weight > 0.
  # print("DEBUG: bounds on weight right now: {low} -- {high}".format(low=lower_bound_on_weight,high=upper_bound_on_weight))
  # print("DEBUG: bounds on burst rate right now: {low} -- {high}".format(low=lower_bound_on_burst_rate,high=upper_bound_on_burst_rate))
  
  print "adaptation #"+str(adaptation_iteration)+": setting weight to "+str(weight)+" ..."
  [size,cons,neuronsE,espikes,noise,GIDoffset] = nest_meta.go_create_network(yamlobj,weight,WEIGHT_NOISE,NOISE_RATE)
  nest.Simulate(ADAPTATION_SIMULATION_TIME)
  tauMS = 50
  burst_rate = nest_meta.determine_burst_rate(nest.GetStatus(espikes, "events")[0]["senders"].flatten().tolist(), nest.GetStatus(espikes, "events")[0]["times"].flatten().tolist(), tauMS, ADAPTATION_SIMULATION_TIME, size)
  print "-> the burst rate is "+str(burst_rate)+" Hz"
  # update bounds on burst_rate
  if burst_rate > TARGET_BURST_RATE:
    if burst_rate < upper_bound_on_burst_rate or (burst_rate==upper_bound_on_burst_rate and weight<upper_bound_on_weight):
      print "-> new upper bound for burst rate and weight found."
      upper_bound_on_burst_rate = burst_rate
      upper_bound_on_weight = weight
  else:
    if burst_rate > lower_bound_on_burst_rate or (burst_rate==lower_bound_on_burst_rate and weight>lower_bound_on_weight):
      print "-> new lower bound for burst rate and weight found."
      lower_bound_on_burst_rate = burst_rate
      lower_bound_on_weight = weight
  
  adaptation_iteration += 1
  last_burst_rates.append(burst_rate)
  last_JEs.append(weight)
  assert adaptation_iteration < MAX_ADAPTATION_ITERATIONS

print "\n----------------------------- auto-burst stage IV.) actual simulation -----------------------------"
[size,cons,neuronsE,espikes,noise,GIDoffset] = nest_meta.go_create_network(yamlobj,weight,WEIGHT_NOISE,NOISE_RATE)
endbuild = time.time()

# --- simulate ---
print "Simulating..."
nest.Simulate(SIMULATION_TIME)
endsimulate = time.time()

build_time = endbuild - startbuild
sim_time = endsimulate - endbuild

totalspikes = nest.GetStatus(espikes, "n_events")[0]
print "Number of neurons : ", size
print "Number of spikes recorded: ", totalspikes
print "Avg. spike rate of neurons: %.2f Hz" % (totalspikes/(size*SIMULATION_TIME/1000.))
print "Building time: %.2f s" % build_time
print "Simulation time: %.2f s" % sim_time

print "Saving spike times to disk..."
inputFile = open(spiketimefilename,"w")
# output spike times, in ms
print >>inputFile, "\n".join([str(x) for x in nest.GetStatus(espikes, "events")[0]["times"] ])
inputFile.close()

inputFile = open(spikeindexfilename,"w")
# remove offset, such that the output array starts with 0
print >>inputFile, "\n".join([str(x-GIDoffset) for x in nest.GetStatus(espikes, "events")[0]["senders"] ])
inputFile.close()
