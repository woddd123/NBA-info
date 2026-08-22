export const getStorage = (key, defaultValue = null) => {
  try {
    const value = localStorage.getItem(key)
    return value ? JSON.parse(value) : defaultValue
  } catch (e) {
    return defaultValue
  }
}

// 返回是否写入成功，调用方（如缓存层）需要据此在配额满时腾空间
export const setStorage = (key, value) => {
  try {
    localStorage.setItem(key, JSON.stringify(value))
    return true
  } catch (e) {
    console.warn('Set storage failed:', key, e.message)
    return false
  }
}

export const removeStorage = (key) => {
  localStorage.removeItem(key)
}

export const clearStorage = () => {
  localStorage.clear()
}
