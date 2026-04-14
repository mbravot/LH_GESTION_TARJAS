import { Button } from '@/components/ui/button'

export const PageHeader = ({ title, description, action, actionLabel, actionIcon: ActionIcon }) => {
  return (
    <div className="flex items-center justify-between">
      <div>
        <h1 className="text-2xl font-bold text-foreground">{title}</h1>
        {description && (
          <p className="text-sm text-text-secondary mt-1">{description}</p>
        )}
      </div>
      {action && (
        <Button onClick={action} className="bg-primary hover:bg-primary-dark text-white">
          {ActionIcon && <ActionIcon className="h-4 w-4 mr-2" />}
          {actionLabel}
        </Button>
      )}
    </div>
  )
}
