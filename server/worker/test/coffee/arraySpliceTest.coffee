HEADER_BATCH_SIZE = 2

uids = [
  'a'
  'b'
  'c'
  'd'
  'e'
]

uidBatches = []

while uids and uids.length
  console.log 'in loop, uids: ', uids, ', uidBatches: ', uidBatches
  uidBatches.push uids.splice 0, HEADER_BATCH_SIZE

console.log uidBatches