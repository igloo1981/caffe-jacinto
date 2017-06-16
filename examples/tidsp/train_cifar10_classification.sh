#!/bin/bash

#-------------------------------------------------------
DATE_TIME=`date +'%Y-%m-%d_%H-%M-%S'`
#-------------------------------------------------------

#-------------------------------------------------------
model_name=jacintonet11
dataset=cifar10
folder_name=training/"$model_name"_"$dataset"_"$DATE_TIME";mkdir $folder_name

#------------------------------------------------
LOG=$folder_name/train-log_"$DATE_TIME".txt
exec &> >(tee -a "$LOG")
echo Logging output to "$LOG"

#------------------------------------------------
caffe="../../build/tools/caffe.bin"

#-------------------------------------------------------
max_iter=64000
base_lr=0.1
threshold_step_factor=1e-6
type=SGD
batch_size=64
total_stride=2
#-------------------------------------------------------
solver_param="{'type':'$type','base_lr':$base_lr,'max_iter':$max_iter,'power':0.5,'test_interval':1000}"

base_lr=1e-3  #use a lower lr for fine tuning
sparse_solver_param="{'type':'$type','base_lr':$base_lr,'max_iter':$max_iter,'power':0.5,'test_interval':1000,\
'sparse_mode':1,'display_sparsity':1000}"

quant_solver_param="{'type':'$type','base_lr':$base_lr,'max_iter':$max_iter,'power':0.5,'test_interval':1000,\
'sparse_mode':1,'display_sparsity':1000,'insert_quantization_param':1,'quantization_start_iter':2000,'snapshot_log':1}"

#-------------------------------------------------------
stage="stage0"
config_name=$folder_name/$stage;mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','pretrain_model':None,\
'num_output':10,'image_width':32,'image_height':32,'crop_size':32,'total_stride':$total_stride,\
'accum_batch_size':$batch_size,'batch_size':$batch_size,\
'train_data':'./data/cifar10_train_lmdb','test_data':'./data/cifar10_test_lmdb',\
'num_test_image':10000,'test_batch_size':50}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param="$solver_param"
config_name_prev=$config_name


#Threshold step
stage="stage1"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','pretrain_model':'$weights',\
'num_output':10,'image_width':32,'image_height':32,'crop_size':32,'total_stride':$total_stride,\
'accum_batch_size':$batch_size,'batch_size':$batch_size,\
'train_data':'./data/cifar10_train_lmdb','test_data':'./data/cifar10_test_lmdb',\
'num_test_image':10000,'test_batch_size':50}" 
$caffe threshold --threshold_fraction_low 0.40 --threshold_fraction_mid 0.70 --threshold_fraction_high 0.70 --threshold_value_max 0.2 --threshold_value_maxratio 0.2 --threshold_step_factor $threshold_step_factor --model="$config_name_prev/deploy.prototxt" --gpu="0" --weights=$weights --output=$config_name/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name_prev=$config_name

#fine tuning
stage="stage2"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','pretrain_model':'$weights',\
'num_output':10,'image_width':32,'image_height':32,'crop_size':32,'total_stride':$total_stride,\
'accum_batch_size':$batch_size,'batch_size':$batch_size,\
'train_data':'./data/cifar10_train_lmdb','test_data':'./data/cifar10_test_lmdb',\
'num_test_image':10000,'test_batch_size':50}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param=$sparse_solver_param
config_name_prev=$config_name

#Threshold step
stage="stage3"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','pretrain_model':'$weights',\
'num_output':10,'image_width':32,'image_height':32,'crop_size':32,'total_stride':$total_stride,\
'accum_batch_size':$batch_size,'batch_size':$batch_size,\
'train_data':'./data/cifar10_train_lmdb','test_data':'./data/cifar10_test_lmdb',\
'num_test_image':10000,'test_batch_size':50}" 
$caffe threshold --threshold_fraction_low 0.40 --threshold_fraction_mid 0.80 --threshold_fraction_high 0.80 --threshold_value_max 0.2 --threshold_value_maxratio 0.2 --threshold_step_factor $threshold_step_factor --model="$config_name_prev/deploy.prototxt" --gpu="0" --weights=$weights --output=$config_name/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name_prev=$config_name

#fine tuning
stage="stage4"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','pretrain_model':'$weights',\
'num_output':10,'image_width':32,'image_height':32,'crop_size':32,'total_stride':$total_stride,\
'accum_batch_size':$batch_size,'batch_size':$batch_size,\
'train_data':'./data/cifar10_train_lmdb','test_data':'./data/cifar10_test_lmdb',\
'num_test_image':10000,'test_batch_size':50}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param=$sparse_solver_param
config_name_prev=$config_name

#Threshold step
stage="stage5"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','pretrain_model':'$weights',\
'num_output':10,'image_width':32,'image_height':32,'crop_size':32,'total_stride':$total_stride,\
'accum_batch_size':$batch_size,'batch_size':$batch_size,\
'train_data':'./data/cifar10_train_lmdb','test_data':'./data/cifar10_test_lmdb',\
'num_test_image':10000,'test_batch_size':50}" 
$caffe threshold --threshold_fraction_low 0.40 --threshold_fraction_mid 0.90 --threshold_fraction_high 0.90 --threshold_value_max 0.2 --threshold_value_maxratio 0.2 --threshold_step_factor $threshold_step_factor --model="$config_name_prev/deploy.prototxt" --gpu="0" --weights=$weights --output=$config_name/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name_prev=$config_name

#fine tuning
stage="stage6"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','pretrain_model':'$weights',\
'num_output':10,'image_width':32,'image_height':32,'crop_size':32,'total_stride':$total_stride,\
'accum_batch_size':$batch_size,'batch_size':$batch_size,\
'train_data':'./data/cifar10_train_lmdb','test_data':'./data/cifar10_test_lmdb',\
'num_test_image':10000,'test_batch_size':50}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param=$sparse_solver_param
config_name_prev=$config_name

#quantization
stage="stage7"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','pretrain_model':'$weights',\
'num_output':10,'image_width':32,'image_height':32,'crop_size':32,'total_stride':$total_stride,\
'accum_batch_size':$batch_size,'batch_size':$batch_size,\
'train_data':'./data/cifar10_train_lmdb','test_data':'./data/cifar10_test_lmdb',\
'num_test_image':10000,'test_batch_size':50}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param=$quant_solver_param
config_name_prev=$config_name


