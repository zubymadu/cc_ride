import { Smartphone, Download, Shield, Wifi } from 'lucide-react'

const APK_URL = '/api/uploads/ccride-debug.apk'
const APP_VERSION = '1.0.4-debug'

export default function DownloadPage() {
  return (
    <div className="min-h-screen bg-gray-950 flex items-center justify-center p-6">
      <div className="max-w-md w-full">
        {/* Logo / Header */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center w-20 h-20 rounded-2xl bg-indigo-600 mb-4">
            <Smartphone size={40} className="text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white">CC Ride</h1>
          <p className="text-gray-400 mt-1">Corporate Ride-Hailing Platform</p>
        </div>

        {/* Download card */}
        <div className="bg-gray-900 border border-gray-800 rounded-2xl p-8 shadow-xl">
          <div className="flex items-center gap-3 mb-6">
            <div className="flex-1">
              <p className="text-white font-semibold text-lg">Android App</p>
              <p className="text-gray-500 text-sm">Version {APP_VERSION}</p>
            </div>
            <span className="text-xs font-medium px-3 py-1 rounded-full bg-yellow-500/15 text-yellow-400 border border-yellow-500/30">
              Debug Build
            </span>
          </div>

          <a
            href={APK_URL}
            download="ccride-debug.apk"
            className="flex items-center justify-center gap-3 w-full py-4 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-semibold text-base transition-colors"
          >
            <Download size={20} />
            Download APK
          </a>

          {/* Install instructions */}
          <div className="mt-6 space-y-3">
            <p className="text-gray-400 text-xs font-semibold uppercase tracking-wider">Installation steps</p>
            {[
              { icon: Shield, text: 'Enable "Install unknown apps" in Android Settings → Security' },
              { icon: Download, text: 'Tap the downloaded APK file to install' },
              { icon: Wifi, text: 'Make sure you have an active internet connection on first launch' },
            ].map(({ icon: Icon, text }, i) => (
              <div key={i} className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-gray-800 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <Icon size={13} className="text-gray-400" />
                </div>
                <p className="text-gray-400 text-sm">{text}</p>
              </div>
            ))}
          </div>

          <p className="mt-6 text-center text-gray-600 text-xs">
            For internal testing only · Not for distribution
          </p>
        </div>

        <p className="text-center text-gray-700 text-xs mt-6">
          © {new Date().getFullYear()} CC Ride
        </p>
      </div>
    </div>
  )
}
