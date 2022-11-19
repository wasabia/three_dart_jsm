import 'index.dart';

getFloatLength(floatLength) {
  // ensure chunk size alignment (STD140 layout)

  return floatLength + ((gpuChunkSize - (floatLength % gpuChunkSize)) % gpuChunkSize);
}

getVectorLength(count, [vectorLength = 4]) {
  var strideLength = getStrideLength(vectorLength);

  var floatLength = strideLength * count;

  return getFloatLength(floatLength);
}

getStrideLength(vectorLength) {
  var strideLength = 4;

  return vectorLength + ((strideLength - (vectorLength % strideLength)) % strideLength);
}
