from matplotlib import pyplot as plt

import numpy as np

def color(icon):
    if icon == 'b':
        return 'gainsboro'
    if icon == 'W':
        return 'whitesmoke'
    if icon == 'O':
        return 'orange'
    if icon == 'B':
        return 'dodgerblue'
    if icon == 'G':
        return 'yellowgreen'    
    if icon == 'K':
        return 'dimgray'

def deck_comp_chart(output_file,
    W = 0, O = 0, B = 0, G = 0, K = 0,
    OO = 0, OB = 0, BB = 0,
    OG = 0, BG = 0, WG = 0,
    OK = 0, BK = 0, WK = 0,
    KG = 0, KK = 0,
    OKB = 0, WOB = 0, KKK = 0, OKG = 0,
    b = 0):

    composition = {   
    # single icon
    'W':W,'O':O,'B':B,'G':G,'K':K,   
    # 2 icons
    'OO':OO,
    'OB':OB,'BB':BB,              
    'OG':OG,'BG':BG,'WG':WG,    
    'OK':OK,'BK':BK,'WK':WK,'KG':KG,'KK':KK,   
    # 3 icons  
    'WOB':WOB,
    'OKG':OKG,
    'OKB':OKB,
    'KKK':KKK,
    #no icons
    'b':b
    }

    # Automatic Sorting:
    #all_icons = composition.keys()

    # Preferred Sorting
    all_icons = [
    'O','B','W','G','K',
    'OO',
    'BB','OB',
    'OG','BG','WG',
    'OK','BK','WK','KG','KK',    
    'OKG','WOB','KKK','OKB',  
    'b'
    ]

    icons = []
    for i in range(len(all_icons)):
        if composition[all_icons[i]] > 0:
            icons.append(all_icons[i])  

    ax = plt.axes( [0.25,0.025,0.95,0.95],polar=True)
    ax.set_facecolor('gainsboro')

    size = sum(composition.values())

    # Inner Ring (1st icon, if any)

    width = []
    theta = []
    radii = []
    bars = []

    for i in range(len(icons)):
        if composition[icons[i]] >= 0:
            wdt = 2*np.pi*composition[icons[i]]/size
            width.append(wdt)
            center = 2*np.pi*sum(
                [composition[icons[j]] for j in range(i)])/size
            shift = wdt/2
            theta.append(center+shift)
            radii.append(1)
            plt.plot([center,center],[1,4],c='white')
            plt.text(center+shift, 3.8, 
                str(composition[icons[i]]),
                horizontalalignment='center',
                verticalalignment='center',
                fontsize=12, color='black')

    bars1 = plt.bar(theta, radii, width=width, bottom=1)

    for i in range(len(icons)):
        bars1[i].set_facecolor(color(icons[i][0]))

    # Middle Ring (2st icon, if any)

    width = []
    theta = []
    radii = []
    bars = []

    for i in range(len(icons)):
        if len(icons[i]) >= 2 and composition[icons[i]] > 0:
            wdt = 2*np.pi*composition[icons[i]]/size
            width.append(wdt)
            center = 2*np.pi*sum(
                [composition[icons[j]] for j in range(i)])/size
            shift = wdt/2
            theta.append(center+shift)
            radii.append(1)

    bars2 = plt.bar(theta, radii, width=width, bottom=2)

    icons2 = []
    for i in range(len(icons)):
        if len(icons[i]) >= 2 and composition[icons[i]] > 0:
            icons2.append(icons[i])

    for i in range(len(icons2)):
            bars2[i].set_facecolor(color(icons2[i][1]))

    # Outher Ring (3rd icon, if any)

    width = []
    theta = []
    radii = []
    bars = []

    for i in range(len(icons)):
        if len(icons[i]) == 3 and composition[icons[i]] > 0:
            wdt = 2*np.pi*composition[icons[i]]/size
            width.append(wdt)
            center = 2*np.pi*sum(
                [composition[icons[j]] for j in range(i)])/size
            shift = wdt/2
            theta.append(center+shift)
            radii.append(1)

    bars3 = plt.bar(theta, radii, width=width, bottom=3)

    icons3 = []

    for i in range(len(icons)):
        if len(icons[i]) == 3 and composition[icons[i]] > 0:
            icons3.append(icons[i])

    for i in range(len(icons3)):
        bars3[i].set_facecolor(color(icons3[i][2]))

    lines, labels = plt.thetagrids([(360./size)*i for i in 
        range(size)], [])
    lines, labels = plt.rgrids([1,2,3,4], [])
    ax.grid(linewidth=1.4,c='gainsboro')

    ax.text(0.5, 0.515, str(size),
        horizontalalignment='center',
        verticalalignment='center',
        fontsize=16, color='black',
        transform=ax.transAxes )

    ax.text(0.5, 0.465, 'cards',
        horizontalalignment='center',
        verticalalignment='center',
        fontsize=9, color='black',
        transform=ax.transAxes )

    plt.savefig(output_file, bbox_inches = 'tight',
        pad_inches = .1)

    plt.show()
