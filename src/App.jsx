import { Button } from '@/components/ui/button'
import { useAuthStore } from '@/store/authStore'
import { toast } from 'sonner'

const App = () => {
  const user = useAuthStore((s) => s.user)

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center">
      <div className="bg-card p-8 rounded-xl shadow-lg text-center space-y-4">
        <h1 className="text-3xl font-bold text-primary">
          LH Gestion Tarjas
        </h1>
        <p className="text-text-secondary">
          Setup completo. Stack listo para desarrollo.
        </p>
        <div className="flex gap-2 justify-center">
          <Button
            className="bg-primary hover:bg-primary-dark text-white"
            onClick={() => toast.success('Toast funcionando')}
          >
            Test Toast
          </Button>
          <Button
            variant="outline"
            onClick={() => {
              document.documentElement.classList.toggle('dark')
            }}
          >
            Toggle Dark Mode
          </Button>
        </div>
        <p className="text-xs text-text-secondary">
          User: {user ? user.sub : 'No autenticado'} |
          API: {import.meta.env.VITE_API_URL}
        </p>
      </div>
    </div>
  )
}

export default App
