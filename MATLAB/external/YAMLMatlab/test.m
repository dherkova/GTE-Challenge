function out = test(x)
clear all
s=ReadYaml('/home/jirka/Software/yamlmatlab/trunk/Tests/Data/test_primitives/simple.yaml')
out = x+1;
end