import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

function App() {
    return (
        <main className="min-h-screen bg-background p-8">
            <div className="mx-auto max-w-lg space-y-6">
                <h1 className="text-3xl font-bold text-foreground">Dostar</h1>
                <Card>
                    <CardHeader>
                        <CardTitle>Create Todo</CardTitle>
                        <CardDescription>Add a new task to your list.</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="title">Title</Label>
                            <Input id="title" placeholder="What needs doing?" />
                        </div>
                        <Button>Add Todo</Button>
                        <Button variant="outline" className="ml-2">Cancel</Button>
                    </CardContent>
                </Card>
            </div>
        </main>
    );
}

export default App;
