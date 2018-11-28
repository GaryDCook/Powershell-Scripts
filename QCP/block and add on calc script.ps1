[int] $vcpu = 127
[int] $mem = 580
[int] $stor = 10000
[int] $band = 50
[int] $pip = 1
[int] $net = 1
$blockCPU = 12
$blockMem = 100
$blockStor = 500
$bcpu = [math]::ceiling($vcpu/$blockCPU)
$bmem = [math]::ceiling($mem/$blockMem)
$bstor = [math]::ceiling($stor/$blockStor)
$tblock = [math]::min($bcpu,$bmem)
$blocks = [math]::min($tblock,$bstor)
$bandcount = [math]::ceiling(($band-5)/5)
$pipcount = $pip
$netcount = $net
$1tbs = [math]::floor(($stor-($blocks*$blockStor))/1000)
if ($1tbs -gt 0)
{
$1TBstorcount = $1tbs
}
else
{
$1TBstorcount = 0
}
$50gbs = [math]::ceiling(($stor-(($blocks*$blockStor)+($1TBstorcount*1000)))/50)
if ($50gbs -gt 0)
{
$50GBstorcount = $50gbs
}
else
{
$50GBstorcount = 0
}
$vcpus = $vcpu-($blockCPU*$blocks)
if ($vcpus -gt 0 )
{
$vcpucount = [math]::ceiling($vcpus/4)
}
else
{
$vcpucount = 0
}
$mems = $mem-($blockmem*$blocks)
if ($mems -gt 0)
{
$memcount = [math]::ceiling($mems/4)
}
else
{
$memcount = 0
}

$blocks
$netcount
$pipcount
$50GBstorcount
$1TBstorcount
$vcpucount
$memcount
$bandcount
