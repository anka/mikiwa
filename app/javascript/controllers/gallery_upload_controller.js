import { Controller } from "@hotwired/stimulus"

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]
const MAX_SIZE_BYTES = 10 * 1024 * 1024
const MAX_SIZE_MB = 10

// F29: Mehrfach-Upload mit Drag & Drop und Per-File-Progress.
// Nutzt einen dedizierten Endpunkt POST /galleries/:id/add_photo,
// der pro Datei eine eigene Anfrage erhält. Damit lässt sich pro
// Datei ein eigener Progress-Indikator zeigen, und einzelne
// Fehler stoppen die Queue nicht.
export default class extends Controller {
  static targets = ["input", "queue", "summary"]
  static values  = { endpoint: String, csrfToken: String }

  connect() {
    this.dz = this.element
    this.dz.addEventListener("dragover",  e => { e.preventDefault(); this.dz.classList.add("mw-gallery-dropzone--active") })
    this.dz.addEventListener("dragleave", () => this.dz.classList.remove("mw-gallery-dropzone--active"))
    this.dz.addEventListener("drop", e => {
      e.preventDefault()
      this.dz.classList.remove("mw-gallery-dropzone--active")
      this.queueFiles(Array.from(e.dataTransfer.files))
    })
  }

  pick(event) {
    this.queueFiles(Array.from(event.target.files))
    event.target.value = ""
  }

  queueFiles(files) {
    if (files.length === 0) return
    files.forEach(file => this.uploadFile(file))
    this.refreshSummary()
  }

  uploadFile(file) {
    const row = this.createRow(file)
    this.queueTarget.appendChild(row)

    const validation = this.validate(file)
    if (validation) {
      this.markFailed(row, validation)
      this.refreshSummary()
      return
    }

    const fd = new FormData()
    fd.append("photo", file)

    const xhr = new XMLHttpRequest()
    xhr.open("POST", this.endpointValue)
    xhr.setRequestHeader("Accept", "application/json")
    xhr.setRequestHeader("X-CSRF-Token", this.csrfTokenValue)

    xhr.upload.addEventListener("progress", e => {
      if (!e.lengthComputable) return
      this.setProgress(row, Math.round((e.loaded / e.total) * 100))
    })
    xhr.addEventListener("load", () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        this.markDone(row)
        this.refreshSummary()
        if (this.allDone()) this.scheduleReload()
      } else {
        let msg = "Upload fehlgeschlagen"
        try { msg = JSON.parse(xhr.responseText).error || msg } catch (e) {}
        this.markFailed(row, msg)
        this.refreshSummary()
      }
    })
    xhr.addEventListener("error", () => {
      this.markFailed(row, "Netzwerkfehler")
      this.refreshSummary()
    })

    xhr.send(fd)
  }

  validate(file) {
    if (!ALLOWED_TYPES.includes(file.type)) {
      return `Format nicht erlaubt (JPEG, PNG, HEIC, WebP)`
    }
    if (file.size > MAX_SIZE_BYTES) {
      return `Datei zu groß (max. ${MAX_SIZE_MB} MB)`
    }
    return null
  }

  createRow(file) {
    const row = document.createElement("div")
    row.className = "mw-upload-row"
    row.dataset.status = "pending"
    row.innerHTML = `
      <div class="mw-upload-row__name">${this.escape(file.name)}</div>
      <div class="mw-upload-row__progress"><div class="mw-upload-row__bar"></div></div>
      <div class="mw-upload-row__status">…</div>
    `
    return row
  }

  setProgress(row, pct) {
    const bar = row.querySelector(".mw-upload-row__bar")
    if (bar) bar.style.width = `${pct}%`
    const status = row.querySelector(".mw-upload-row__status")
    if (status) status.textContent = `${pct}%`
  }

  markDone(row) {
    row.dataset.status = "done"
    this.setProgress(row, 100)
    row.querySelector(".mw-upload-row__status").textContent = "✓"
  }

  markFailed(row, message) {
    row.dataset.status = "failed"
    row.querySelector(".mw-upload-row__status").textContent = `Fehler: ${message}`
    const bar = row.querySelector(".mw-upload-row__bar")
    if (bar) bar.style.width = "100%"
  }

  refreshSummary() {
    if (!this.hasSummaryTarget) return
    const rows  = Array.from(this.queueTarget.querySelectorAll(".mw-upload-row"))
    const total = rows.length
    const done  = rows.filter(r => r.dataset.status === "done").length
    const fail  = rows.filter(r => r.dataset.status === "failed").length
    this.summaryTarget.textContent = total === 0
      ? ""
      : `${done}/${total} hochgeladen${fail > 0 ? ` · ${fail} fehlgeschlagen` : ""}`
  }

  allDone() {
    const rows = Array.from(this.queueTarget.querySelectorAll(".mw-upload-row"))
    if (rows.length === 0) return false
    return rows.every(r => r.dataset.status === "done" || r.dataset.status === "failed")
  }

  scheduleReload() {
    if (this.reloadTimer) return
    this.reloadTimer = setTimeout(() => window.location.reload(), 1500)
  }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
