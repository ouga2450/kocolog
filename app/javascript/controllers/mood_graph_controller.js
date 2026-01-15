import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"
import "chartjs-adapter-date-fns"

function themeColor(variable) {
  return getComputedStyle(document.documentElement)
    .getPropertyValue(variable)
    .trim()
}

export default class extends Controller {
  static values = {
    values: Array,
    unit: String
  }

  connect() {
    if (!this.valuesValue || this.valuesValue.length === 0) return

    const canvas = this.element.querySelector("canvas")
    const time = this.timeConfig()

    // テーマカラー取得
    const primary     = themeColor("--color-primary")
    const base200     = themeColor("--color-base-200")
    const base300     = themeColor("--color-base-300")
    const baseContent = themeColor("--color-base-content")
    const neutral     = themeColor("--color-neutral")
    const accent      = themeColor("--color-accent")

    // 時系列データ
    const data = this.valuesValue
      .map((v) => {
        const rawTime = v?.time ?? v?.[0]
        const value = v?.value ?? v?.[1]
        if (rawTime == null || value == null) return null

        const rounded = this.roundTime(
          rawTime,
          time.unit,
          time.stepSize
        )

        return { x: rounded, y: value }
      })
      .filter(Boolean)

    this.chart = new Chart(canvas, {
      type: "line",
      data: {
        datasets: [
          {
            data,

            // 線
            borderColor: primary,
            borderWidth: 2,
            tension: 0.4,

            fill: true,
            backgroundColor: (context) => {
              const chart = context.chart
              const { ctx, chartArea } = chart
              if (!chartArea) return null

              const gradient = ctx.createLinearGradient(0, chartArea.top, 0, chartArea.bottom)
              gradient.addColorStop(0, `${primary}33`)
              gradient.addColorStop(1, `${primary}00`)
              return gradient
            },

            pointRadius: 0,
            pointHoverRadius: 5,
            pointHitRadius: 12,
            pointBackgroundColor: accent,
            pointBorderColor: base200,
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,

        interaction: {
          mode: "nearest",
          intersect: false
        },

        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: base200,
            titleColor: baseContent,
            bodyColor: baseContent,
            borderColor: base300,
            borderWidth: 1,
            displayColors: false,
            callbacks: {
              title: (items) => {
                const raw = items[0].parsed.x
                const date = new Date(raw)

                switch (this.unitValue) {
                  case "quarter_hour":
                  case "half_hour":
                  case "hour":
                    return date.toLocaleTimeString("ja-JP", {
                      hour: "2-digit",
                      minute: "2-digit"
                    })

                  case "day":
                  case "three_days":
                  case "week":
                    return date.toLocaleDateString("ja-JP", {
                      month: "2-digit",
                      day: "2-digit"
                    })

                  case "month":
                    return date.toLocaleDateString("ja-JP", {
                      year: "numeric",
                      month: "2-digit"
                    })

                  default:
                    return date.toLocaleString("ja-JP")
                }
              },
              label: (context) => {
                const value = context.parsed.y
                const rounded = Math.round(value * 100) / 100
                return `気分：${rounded}`
              }
            }
          }
        },
        scales: {
          x: {
            type: "time",
            min: data[0]?.x,
            max: data[data.length - 1]?.x,
            time: {
              unit: time.unit,
              stepSize: time.stepSize,
              displayFormats: {
                [time.unit]: time.format
              }
            },
            grid: {
              color: base300,
              drawBorder: false,
              borderDash: [3, 6]
            },
            ticks: {
              source: "data",
              color: neutral,
              autoSkip: false,
              maxRotation: 0,
              font: { size: 11 }
            }
          },
          y: {
            min: 1,
            max: 5,
            grid: {
              color: base300,
              borderDash: [2, 2]
            },
            ticks: {
              stepSize: 1,
              color: neutral,
              font: { size: 11 }
            }
          }
        }
      }
    })
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
  }

  roundTime(date, unit, step) {
    const time = new Date(date).getTime()

    let stepMs

    switch (unit) {
      case "minute":
        stepMs = step * 60 * 1000
        break
      case "hour":
        stepMs = 60 * 60 * 1000
        break
      case "day":
        stepMs = 24 * 60 * 60 * 1000
        break
      default:
        return new Date(time)
    }

    return new Date(Math.floor(time / stepMs) * stepMs)
  }

  timeConfig() {
    switch (this.unitValue) {
      case "quarter_hour":
        return { unit: "minute", stepSize: 15, format: "HH:mm" }
      case "half_hour":
        return { unit: "minute", stepSize: 30, format: "HH:mm" }
      case "hour":
        return { unit: "hour", stepSize: 1, format: "dd HH:mm" }
      case "day":
        return { unit: "day", stepSize: 1, format: "MM/dd" }
      case "three_days":
        return { unit: "day", stepSize: 3, format: "MM/dd" }
      case "week":
        return { unit: "week", stepSize: 1, format: "MM/dd" }
      case "month":
        return { unit: "month", stepSize: 1, format: "yyyy/MM" }
      default:
        return { unit: "day", stepSize: 1, format: "MM/dd" }
    }
  }
}
