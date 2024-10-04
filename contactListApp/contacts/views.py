# contacts/views.py

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth.decorators import login_required
from .forms import SignupForm, ContactForm
from .models import Contact

# Index page: signup/signin options
def index(request):
    return render(request, 'contacts/index.html')

# Sign up view
def signup(request):
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('signin')  # Redirect to signin after signup
    else:
        form = SignupForm()
    return render(request, 'contacts/signup.html', {'form': form})

# Sign in view
def signin(request):
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            username = form.cleaned_data.get('username')
            password = form.cleaned_data.get('password')
            user = authenticate(username=username, password=password)
            if user is not None:
                login(request, user)
                return redirect('dashboard')
    else:
        form = AuthenticationForm()
    return render(request, 'contacts/signin.html', {'form': form})

# Logout view
def signout(request):
    logout(request)
    return redirect('index')

# Dashboard view with list of contacts
@login_required
def dashboard(request):
    contacts = Contact.objects.filter(user=request.user)
    return render(request, 'contacts/dashboard.html', {'contacts': contacts})

# Add a new contact
@login_required
def add_contact(request):
    if request.method == 'POST':
        form = ContactForm(request.POST)
        if form.is_valid():
            contact = form.save(commit=False)
            contact.user = request.user  # Assign the contact to the logged-in user
            contact.save()
            return redirect('dashboard')
    else:
        form = ContactForm()
    return render(request, 'contacts/contact_form.html', {'form': form})

# Edit a contact
@login_required
def edit_contact(request, pk):
    contact = get_object_or_404(Contact, pk=pk, user=request.user)
    if request.method == 'POST':
        form = ContactForm(request.POST, instance=contact)
        if form.is_valid():
            form.save()
            return redirect('dashboard')
    else:
        form = ContactForm(instance=contact)
    return render(request, 'contacts/contact_form.html', {'form': form})

# Delete a contact
@login_required
def delete_contact(request, pk):
    contact = get_object_or_404(Contact, pk=pk, user=request.user)
    if request.method == 'POST':
        contact.delete()
        return redirect('dashboard')
    return render(request, 'contacts/delete_contact.html', {'contact': contact})
