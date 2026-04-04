export const getStorage = (key, defaultValue = null) => {
  try {
    const value = localStorage.getItem(key)
    return value ? JSON.parse(value) : defaultValue
  } catch (e) {
    return defaultValue
  }
}

export const setStorage = (key, value) => {
  try {
    localStorage.setItem(key, JSON.stringify(value))
  } catch (e) {
    console.error('Set storage error:', e)
  }
}

export const removeStorage = (key) => {
  localStorage.removeItem(key)
}

export const clearStorage = () => {
  localStorage.clear()
}
