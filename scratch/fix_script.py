with open('scratch/update_tex.py', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix unescaped underscores in URLs
# 1. language_models_are_unsupervised_multitask_learners.pdf
# 2. arXiv:1907.11692, 2019
code = code.replace(
    'https://cdn.openai.com/better-language-models/language_models_are_unsupervised_multitask_learners.pdf',
    r'https://cdn.openai.com/better-language-models/language\_models\_are\_unsupervised\_multitask\_learners.pdf'
)
code = code.replace(
    r'arXiv preprint arXiv:1907.11692',
    r'arXiv preprint arXiv:1907.11692'
)

# Also let's check any other underscores in references
with open('scratch/update_tex.py', 'w', encoding='utf-8') as f:
    f.write(code)

print('Updated scratch/update_tex.py with escaped underscores')
