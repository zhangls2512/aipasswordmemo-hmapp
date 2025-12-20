export function getSizeString(size: number) {
  if (size < Math.pow(1024, 1)) {
    return size + ' B'
  }
  if (size >= Math.pow(1024, 1) && size < Math.pow(1024, 2)) {
    return (size / Math.pow(1024, 1)).toFixed(2) + ' KB'
  }
  if (size >= Math.pow(1024, 2) && size < Math.pow(1024, 3)) {
    return (size / Math.pow(1024, 2)).toFixed(2) + ' MB'
  }
  if (size >= Math.pow(1024, 3) && size < Math.pow(1024, 4)) {
    return (size / Math.pow(1024, 3)).toFixed(2) + ' GB'
  }
  if (size >= Math.pow(1024, 4)) {
    return (size / Math.pow(1024, 4)).toFixed(2) + ' TB'
  }
  return ''
}